# Migrate from SignalFx Lambda wrappers to Splunk OpenTelemetry Lambda Layer

The SignalFx Lambda wrappers are deprecated. Follow these steps to migrate from the SignalFx Lambda wrappers to
the Splunk OpenTelemetry Lambda Layer.

## Remove the SignalFx Lambda wrapper from your function

Before installing the Splunk OpenTelemetry Lambda Layer, remove any
previous instrumentation, including the SignalFx Lambda wrapper.

-   If you installed the SignalFx wrapper as a layer, remove it from
    console.
-   If you referenced the wrapper directly, remove the wrapper from
    the build.

## Replace the handler for your function

The Splunk OpenTelemetry Lambda Layer does not require setting a custom
handler in `Runtime settings`.

To replace the SignalFx handler with your function handler, follow these
steps:

1.  In the AWS Lambda console, open the function that you are
    instrumenting.
2.  Navigate to `Code` > `Runtime settings`, then cick `Edit`.
3.  Replace the SignalFx handler with the handler of your function.
4.  Click `Save`.

## Install the Splunk OpenTelemetry Lambda Layer

Once you've removed the SignalFx Lambda wrapper from your function,
install the new Splunk OpenTelemetry Lambda Layer.

## Update the environment variables

The following table shows SignalFx Lambda wrapper environment variables
and their Splunk OpenTelemetry Lambda Layer equivalents:

| SignalFx environment variable                      | OpenTelemetry environment variable                                                                                |
|----------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `SIGNALFX_ACCESS_TOKEN` and `SIGNALFX_AUTH_TOKEN`  | `SPLUNK_ACCESS_TOKEN`                                                                                             |
| `SIGNALFX_TRACING_URL` and `SIGNALFX_API_HOSTNAME` | `OTEL_EXPORTER_OTLP_ENDPOINT` or `OTEL_EXPORTER_JAEGER_ENDPOINT`, depending on which trace exporter you're using. |
| `SIGNALFX_METRICS_URL`                             | You can set either the `SPLUNK_REALM` or `SPLUNK_INGEST_URL` environment variables.                               |
| `SIGNALFX_SEND_TIMEOUT`                            | `OTEL_INSTRUMENTATION_AWS_LAMBDA_FLUSH_TIMEOUT`.                                                                  |
| `SIGNALFX_LAMBDA_HANDLER`                          | `AWS_LAMBDA_EXEC_WRAPPER`. You must select one of the supported handlers.                                         |
| `SIGNALFX_SERVICE_NAME`                            | `OTEL_SERVICE_NAME=<name_of_the_service>`                                                                         |
| `SIGNALFX_ENV`                                     | `OTEL_RESOURCE_ATTRIBUTES=deployment.environment=<name_of_the_environment>`                                       |
