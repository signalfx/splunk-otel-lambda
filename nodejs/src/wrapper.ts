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
import { diag, DiagConsoleLogger } from "@opentelemetry/api";
import { getEnv } from '@opentelemetry/core';
import { startTracing } from '@splunk/otel';

// configure lambda logging
const logLevel = getEnv().OTEL_LOG_LEVEL
diag.setLogger(new DiagConsoleLogger(), logLevel)

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

const instrumentations = [
  new AwsInstrumentation({
    suppressInternalInstrumentation: true,
  }),
  new AwsLambdaInstrumentation(),
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
    resource
  };
  startTracing({tracerConfig: tracerConfig, instrumentations: instrumentations})
}

initializeProvider()

