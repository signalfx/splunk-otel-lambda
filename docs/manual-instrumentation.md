# Manually Instrument Heavy Lambda Workloads

The Splunk OpenTelemetry Lambda Layer creates the Lambda invocation span and configures export to Splunk Observability Cloud. Some Lambda functions still need explicit spans when important work happens in libraries or code paths that automatic instrumentation does not cover, such as custom database clients, long-running data processing, batch operations, or application-specific logging.

Use manual instrumentation for those gaps. You should not create a second OpenTelemetry SDK, exporter, or tracer provider in the function. Let the layer own SDK startup and export, and use the OpenTelemetry API from your application code to add spans and log correlation data to the active Lambda trace.

## Deployment Checklist

Keep the regular layer setup for your runtime:

| Runtime | Wrapper |
| --- | --- |
| Java `RequestHandler` | `/opt/otel-handler` |
| Java `RequestStreamHandler` | `/opt/otel-stream-handler` |
| Java API Gateway proxy handler | `/opt/otel-proxy-handler` |
| Node.js | `/opt/nodejs-otel-handler` |

Set `SPLUNK_ACCESS_TOKEN` and `SPLUNK_REALM` as described in the Lambda layer setup instructions. The layer configures the default OTLP exporter, propagators, sampler, and flush timeout.

In the function package, add only the OpenTelemetry API dependency needed by your application code. Do not initialize a new SDK or configure another exporter from the function.

Use manual spans around work that needs better visibility:

- Database calls that are not automatically traced.
- Custom SDKs or clients that do not have OpenTelemetry instrumentation.
- Expensive serialization, enrichment, batching, or transformation steps.
- Log-heavy code paths where trace and span identifiers make troubleshooting easier.

Avoid recording secrets, raw SQL values, customer data, or other sensitive payloads in span attributes or logs.

## Java

Add the OpenTelemetry API to the Lambda function build so the application code can compile against it. Use the version managed by your build, or align it with the OpenTelemetry version already used by the function.

```xml
<dependency>
  <groupId>io.opentelemetry</groupId>
  <artifactId>opentelemetry-api</artifactId>
</dependency>
```

Create child spans from the active Lambda invocation span. The layer keeps the active context available during the handler invocation.

```java
package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;

public class Function implements RequestHandler<Object, String> {
  private static final Tracer tracer =
      GlobalOpenTelemetry.getTracer("example-heavy-lambda");

  @Override
  public String handleRequest(Object event, Context context) {
    String result = queryDatabase(context);
    return result;
  }

  private String queryDatabase(Context lambdaContext) {
    Span span = tracer.spanBuilder("customer.lookup")
        .setSpanKind(SpanKind.CLIENT)
        .setAttribute("db.system", "postgresql")
        .setAttribute("db.operation", "SELECT")
        .startSpan();

    try (Scope ignored = span.makeCurrent()) {
      logWithTraceContext(lambdaContext, "Starting customer lookup");
      return runQuery();
    } catch (RuntimeException error) {
      span.recordException(error);
      span.setStatus(StatusCode.ERROR, error.getMessage());
      throw error;
    } finally {
      span.end();
    }
  }

  private void logWithTraceContext(Context lambdaContext, String message) {
    Span current = Span.current();
    if (current.getSpanContext().isValid()) {
      lambdaContext.getLogger().log(String.format(
          "%s trace_id=%s span_id=%s",
          message,
          current.getSpanContext().getTraceId(),
          current.getSpanContext().getSpanId()));
    } else {
      lambdaContext.getLogger().log(message);
    }
  }

  private String runQuery() {
    return "ok";
  }
}
```

For async or threaded work, make sure the span is current while the work is scheduled and executed. If work runs outside the handler thread, pass the OpenTelemetry context into that work explicitly.

## Node.js

Add the OpenTelemetry API to the Lambda function package so local builds and tests use the same import path as production.

```json
{
  "dependencies": {
    "@opentelemetry/api": "^1.9.0"
  }
}
```

Create child spans from the active Lambda invocation span. The Node.js wrapper loads before the handler and keeps the active context available during the handler invocation.

```javascript
'use strict';

const {
  context,
  SpanKind,
  SpanStatusCode,
  trace,
} = require('@opentelemetry/api');

const tracer = trace.getTracer('example-heavy-lambda');

exports.handler = async function handler(event) {
  const customer = await withSpan('customer.lookup', async (span) => {
    span.setAttribute('db.system', 'postgresql');
    span.setAttribute('db.operation', 'SELECT');
    logWithTraceContext('Starting customer lookup');
    return queryDatabase(event.customerId);
  });

  return {
    statusCode: 200,
    body: JSON.stringify({ customer }),
  };
};

async function withSpan(name, fn) {
  return tracer.startActiveSpan(name, { kind: SpanKind.CLIENT }, async (span) => {
    try {
      return await fn(span);
    } catch (error) {
      span.recordException(error);
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message,
      });
      throw error;
    } finally {
      span.end();
    }
  });
}

function logWithTraceContext(message) {
  const span = trace.getSpan(context.active());
  const spanContext = span && span.spanContext();

  if (spanContext && spanContext.traceId) {
    console.log(JSON.stringify({
      message,
      trace_id: spanContext.traceId,
      span_id: spanContext.spanId,
    }));
    return;
  }

  console.log(message);
}

async function queryDatabase(customerId) {
  return { id: customerId };
}
```

For ES modules, use `import` instead of `require`:

```javascript
import {
  context,
  SpanKind,
  SpanStatusCode,
  trace,
} from '@opentelemetry/api';
```

## Validation

After deploying the function:

1. Invoke the Lambda function.
2. Confirm that the invocation span still appears in Splunk Observability Cloud.
3. Confirm that the manual span appears as a child of the invocation span.
4. Check error paths to verify exceptions are recorded and spans end.
5. Check logs for `trace_id` and `span_id` values when log correlation was added.

If manual spans are missing, verify that the Lambda layer is attached, `AWS_LAMBDA_EXEC_WRAPPER` points to the wrapper for the runtime, and the function code is not initializing a separate OpenTelemetry SDK.
