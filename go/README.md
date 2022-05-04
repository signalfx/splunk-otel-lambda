# Splunk OpenTelemetry Lambda Go

Due to AWS and GO limitations it's currently not possible to distribute tracing code with a lambda layer or use runtime wrapper scripts to facilitate tracing. Therefore in order to provide observability capabilities for AWS lambdas written in GO, a combination of the [Splunk OpenTelemetry Lambda Layer](https://github.com/signalfx/lambda-layer-versions/blob/master/splunk-apm/README.md) (for metrics) and manual instrumentation (for traces) is required.

## Instrumentation

[GO OpenTelemetry instrumentation for AWS Lambda](https://github.com/open-telemetry/opentelemetry-go-contrib/tree/main/instrumentation/github.com/aws/aws-lambda-go/otellambda) is a module that can be used to trace a lambda execution.

## Examples

The [example lambda](https://github.com/signalfx/tracing-examples/tree/main/opentelemetry-tracing/opentelemetry-lambda/go) shows how to use GO OpenTelemetry instrumentation for AWS Lambda with the Splunk OpenTelemetry Lambda Layer and how to configure it for Splunk direct ingest. 