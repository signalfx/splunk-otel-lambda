/*
 * Copyright Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { diag, DiagConsoleLogger, isSpanContextValid, propagation, context as otelContext, TraceFlags } from "@opentelemetry/api";
import { NodeTracerConfig } from '@opentelemetry/sdk-trace-node';
import { diagLogLevelFromString, getStringFromEnv } from '@opentelemetry/core';
import { detectResources, envDetector, processDetector } from '@opentelemetry/resources';

import { awsLambdaDetector } from '@opentelemetry/resource-detector-aws';
import type { ResponseHook } from '@opentelemetry/instrumentation-aws-lambda';

import { AwsLambdaInstrumentation } from '@opentelemetry/instrumentation-aws-lambda';

import { start } from '@splunk/otel';
import { getInstrumentations } from '@splunk/otel/lib/instrumentations';


// configure lambda logging
const logLevel = getStringFromEnv('OTEL_LOG_LEVEL');
diag.setLogger(new DiagConsoleLogger(), diagLogLevelFromString(logLevel));

// configure flush timeout
let forceFlushTimeoutMillisEnv = parseInt(process.env.OTEL_INSTRUMENTATION_AWS_LAMBDA_FLUSH_TIMEOUT || "")
const forceFlushTimeoutMillis = (isNaN(forceFlushTimeoutMillisEnv) ? 30000 : forceFlushTimeoutMillisEnv)
diag.debug(`ForceFlushTimeout set to: ${forceFlushTimeoutMillis}`);



// AWS lambda instrumentation response hook for Server-Timing support
function getEnvBoolean(key: string, defaultValue = true) {
  const value = process.env[key];

  if (value === undefined) {
    return defaultValue;
  }

  if (['false', 'no', '0'].indexOf(value.trim().toLowerCase()) >= 0) {
    return false;
  }

  return true;
}

function appendHeader(response: any, header: string, value: string) {
  const existing = response[header];

  if (existing === undefined) {
    response[header] = value;
    return;
  }

  if (typeof existing === 'string') {
    response[header] = `${existing}, ${value}`;
    return;
  }

  if (Array.isArray(existing)) {
    existing.push(value);
  }
}

// an educated guess - how to check if particular response is an API Gateway event?
function isApiGatewayResponse(data:any) {
    return (data && data.res && data.res.body && data.res.statusCode);
}

const responseHook: ResponseHook = (span, data) => {

    const serverTimingEnabled = getEnvBoolean(
      'SPLUNK_TRACE_RESPONSE_HEADER_ENABLED',
      true
    );
    const spanContext = span.spanContext();

    if (!isApiGatewayResponse(data) || !serverTimingEnabled || !isSpanContextValid(spanContext)) {
        return;
    }

    if (!data.res.headers) {
        data.res.headers = {};
    }

    const { traceFlags, traceId, spanId } = spanContext;
    const sampled = (traceFlags & TraceFlags.SAMPLED) === TraceFlags.SAMPLED;
    const flags = sampled ? '01' : '00';
    appendHeader(data.res.headers, 'Access-Control-Expose-Headers', 'Server-Timing');
    appendHeader(data.res.headers, 'Server-Timing', `traceparent;desc="00-${traceId}-${spanId}-${flags}"`);
  };

const awsContextPropDisabled = typeof process.env['OTEL_LAMBDA_DISABLE_AWS_CONTEXT_PROPAGATION'] === 'string'
  && process.env['OTEL_LAMBDA_DISABLE_AWS_CONTEXT_PROPAGATION'].toLowerCase() === 'true';

const extraLambdaConfig = awsContextPropDisabled ?
  {
       // enable trace chaining; FIXME should fix this in upstream?
       eventContextExtractor: (event: any, context: any) => {
        const eventContext = propagation.extract(otelContext.active(), context.clientContext?.Custom);
        return eventContext;
      },
  } :
  { };

const instrumentations = [
  new AwsLambdaInstrumentation({
    responseHook,
    ...extraLambdaConfig,
  }),
  ...getInstrumentations(),
];

async function initializeProvider() {
  const resource = detectResources({
    detectors: [awsLambdaDetector, envDetector, processDetector],
  });
  const tracerConfig: NodeTracerConfig = {
    resource,
    forceFlushTimeoutMillis,
  };
  start({tracing: {tracerConfig: tracerConfig, instrumentations: instrumentations}})
}

initializeProvider()
