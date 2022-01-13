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

import { NodeTracerConfig } from '@opentelemetry/sdk-trace-node';
import { awsLambdaDetector } from '@opentelemetry/resource-detector-aws';
import { detectResources, envDetector, processDetector } from '@opentelemetry/resources';
import { diag, DiagConsoleLogger, isSpanContextValid, TraceFlags } from "@opentelemetry/api";
import { getEnv } from '@opentelemetry/core';
import { startTracing } from '@splunk/otel';
import type { ResponseHook } from '@opentelemetry/instrumentation-aws-lambda';

// configure lambda logging
const logLevel = getEnv().OTEL_LOG_LEVEL
diag.setLogger(new DiagConsoleLogger(), logLevel)

// configure flush timeout
let forceFlushTimeoutMillisEnv = parseInt(process.env.OTEL_INSTRUMENTATION_AWS_LAMBDA_FLUSH_TIMEOUT || "")
const forceFlushTimeoutMillis = (isNaN(forceFlushTimeoutMillisEnv) ? 3000 : forceFlushTimeoutMillisEnv)
diag.debug(`ForceFlushTimeout set to: ${forceFlushTimeoutMillis}`);

const { AwsInstrumentation } = require('@opentelemetry/instrumentation-aws-sdk');
const { AwsLambdaInstrumentation } = require('@opentelemetry/instrumentation-aws-lambda');
const { DnsInstrumentation } = require('@opentelemetry/instrumentation-dns');
const { ExpressInstrumentation } = require('@opentelemetry/instrumentation-express');
const { GraphQLInstrumentation } = require('@opentelemetry/instrumentation-graphql');
const { GrpcInstrumentation } = require('@opentelemetry/instrumentation-grpc');
const { HapiInstrumentation } = require('@opentelemetry/instrumentation-hapi');
const { HttpInstrumentation } = require('@opentelemetry/instrumentation-http');
const { IORedisInstrumentation } = require('@opentelemetry/instrumentation-ioredis');
const { KoaInstrumentation } = require('@opentelemetry/instrumentation-koa');
const { MongoDBInstrumentation } = require('@opentelemetry/instrumentation-mongodb');
const { MySQLInstrumentation } = require('@opentelemetry/instrumentation-mysql');
const { NetInstrumentation } = require('@opentelemetry/instrumentation-net');
const { PgInstrumentation } = require('@opentelemetry/instrumentation-pg');
const { RedisInstrumentation } = require('@opentelemetry/instrumentation-redis');

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

const instrumentations = [
  new AwsInstrumentation({
    suppressInternalInstrumentation: true,
  }),
  new AwsLambdaInstrumentation({
    responseHook
  }),
  new DnsInstrumentation(),
  new ExpressInstrumentation(),
  new GraphQLInstrumentation(),
  new GrpcInstrumentation(),
  new HapiInstrumentation(),
  new HttpInstrumentation(),
  new IORedisInstrumentation(),
  new KoaInstrumentation(),
  new MongoDBInstrumentation(),
  new MySQLInstrumentation(),
  new NetInstrumentation(),
  new PgInstrumentation(),
  new RedisInstrumentation(),
];

async function initializeProvider() {
  const resource = await detectResources({
    detectors: [awsLambdaDetector, envDetector, processDetector],
  });
  const tracerConfig: NodeTracerConfig = {
    resource,
    forceFlushTimeoutMillis,
  };
  startTracing({tracerConfig: tracerConfig, instrumentations: instrumentations})
}

initializeProvider()

