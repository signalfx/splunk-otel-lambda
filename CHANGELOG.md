# Changelog

## [Unreleased]

## 0.9.6
- Upstream opentelemetry has deprecated OPENTELEMETRY_COLLECTOR_CONFIG_FILE and
  renamed it to OPENTELEMETRY_COLLECTOR_CONFIG_URI.  Please adjust
  your environments accordingly.

## 0.9.1
- Re-enable python metrics exporting

## 0.9.0
- Update upstream otel-lambda to latest
- Update otel-java dependencies to 2.4
- Update splunk-otel-python to 1.19.1
- Update splunk-otel-js to 2.8.0

## 0.8.0

- Remove ruby support.  Please use manual or upstream ruby instrumentation.
- Update upstream otel-lambda to latest
- Update otel-java dependencies to 2.0.0
- Update splunk-otel-python to 1.17.0
- Update splunk-otel-js to 2.6.1

## 0.7.4

- Update splunk-otel-js to 2.6.0

## 0.7.3

- Update upstream otel-lambda to latest
- Update otel-java dependencies to 1.32.0
- Update splunk-otel-python to 1.16.0
- Update splunk-otel-js to 2.5.1
- Update miscellaneous other java depenencies

## 0.7.2

- Update upstream otel-lambda to latest with java17 (and 21) support

## 0.7.1

- Updated node to splunk-otel 2.5.0
- Updated upstream otel-lambda to latest
- Updated java dependencies, including otel-java sdk 1.30

## 0.7.0

- Updated upstream otel-lambda to latest
- Updated splunk-otel-python to 0.13.0
- Fixed environment variables and collector config to support metrics export

## 0.6.6

- Added SPLUNK_EXTENSION_WRAPPER_ENABLED and
  SPLUNK_LAMBDA_LOCAL_COLLECTOR_ENABLED to control execution of
  these extensions.
- Updated node to splunk-otel 2.4.2

## 0.6.5

- Updated python to splunk-otel 1.12.0
- Updated java dependencies, including otel-java 1.29.0
- Updated to latest upstream otel-lambda
