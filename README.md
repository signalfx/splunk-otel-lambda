---

<p align="center">
  <strong>
    <a href="#get-started">Get Started</a>
    &nbsp;&nbsp;&bull;&nbsp;&nbsp;
    <a href="CONTRIBUTING.md">Get Involved</a>
  </strong>
</p>

<p align="center">
  <img alt="Beta" src="https://img.shields.io/badge/status-beta-informational?style=for-the-badge">
  <a href="https://github.com/signalfx/gdi-specification/releases/tag/v1.2.0">
    <img alt="Splunk GDI specification" src="https://img.shields.io/badge/GDI-1.2.0-blueviolet?style=for-the-badge">
  </a>
  <a href="https://github.com/signalfx/splunk-otel-lambda/actions?query=workflow%3A%22CI+build%22">
    <img alt="Build Status" src="https://img.shields.io/github/workflow/status/signalfx/splunk-otel-lambda/CI%20build?style=for-the-badge">
  </a>
</p>

# Splunk OpenTelemetry Lambda Layer

Splunk OpenTelemetry Lambda is a downstream distribution of the [OpenTelemetry Lambda](https://github.com/open-telemetry/opentelemetry-lambda). Supported OpenTelemetry Lambda layers are preconfigured to use Splunk Observability Cloud as the tracing backend. Users can enhance their existing Lambda functions by adding the Splunk-managed layer directly. 

The following languages are currently supported:

- Java
- Python
- Node.js

Layer ARNs [are published here](https://github.com/signalfx/lambda-layer-versions/).

## Get started 

For complete instructions on how to get started with the Splunk OpenTelemetry Lambda, see [Instrument AWS Lambda functions for Splunk Observability Cloud](https://quickdraw.splunk.com/redirect/?product=Observability&version=current&location=learnmore.aws.lambda.layer) in the official documentation.

If you're using the SignalFx Tracing Library for Node and want to migrate to the Splunk Distribution of OpenTelemetry Node, see [Migrate from SignalFx Lambda wrappers to Splunk OpenTelemetry Lambda Layer](https://quickdraw.splunk.com/redirect/?product=Observability&version=current&location=aws.lambda.migrate) in the official documentation.

## Troubleshooting

For troubleshooting issues with the Splunk OpenTelemetry Lambda, see [Troubleshoot the Splunk OpenTelemetry Lambda Layer](https://quickdraw.splunk.com/redirect/?product=Observability&version=current&location=aws.lambda.tshoot).

## License

Splunk OpenTelemetry Lambda Layer is licensed under the terms of the Apache Software License version 2.0. For more details, see [the license file](./LICENSE).

>ℹ️&nbsp;&nbsp;SignalFx was acquired by Splunk in October 2019. See [Splunk SignalFx](https://www.splunk.com/en_us/investor-relations/acquisitions/signalfx.html) for more information.
