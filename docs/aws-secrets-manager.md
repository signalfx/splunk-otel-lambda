# Using AWS Secrets Manager with the OpenTelemetry Collector Lambda Extension

Use this pattern when a Lambda function uses the Splunk OpenTelemetry Lambda
Layer with the local Collector and you do not want to store the Splunk
Observability Cloud access token in Lambda environment variables.

The Collector can load its configuration from Amazon S3 and resolve the
`X-SF-TOKEN` exporter header from AWS Secrets Manager during Collector
initialization. The token is resolved in memory; the configuration object in S3
is not rewritten.

## When to use this

Use this configuration when:

- The Lambda function uses the Splunk OpenTelemetry Collector layer.
- `SPLUNK_LAMBDA_LOCAL_COLLECTOR_ENABLED` is unset or set to `true`.
- The deployment can grant the Lambda execution role read access to the S3
  configuration object and the AWS Secrets Manager secret.
- The access token must not be configured with `SPLUNK_ACCESS_TOKEN` in Lambda
  environment variables.

Do not fetch the token inside the Lambda handler for this use case. The
Collector extension starts and resolves its configuration during Lambda
initialization, before handler code runs. Handler code cannot reliably override
the header used by the local Collector.

If the local Collector is disabled and the language SDK exports directly to
Splunk Observability Cloud, configure the OTLP exporter headers before the SDK
starts. That direct-export path is separate from the Collector configuration
provider pattern described here.

## How it works

1. AWS Lambda creates an execution environment and provides temporary
   credentials for the Lambda execution role.
2. The Splunk OpenTelemetry Collector extension starts.
3. The Collector reads `OPENTELEMETRY_COLLECTOR_CONFIG_URI`.
4. If the URI uses the `s3://` scheme, the Collector S3 configuration provider
   downloads the Collector configuration from Amazon S3.
5. While resolving the configuration, the Collector Secrets Manager provider
   resolves placeholders such as `${secretsmanager:<secret-name-or-arn>}`.
6. The resolved value is used as the `X-SF-TOKEN` header on the Splunk OTLP
   HTTP exporter.

The same Lambda execution role credentials are used for the S3 and Secrets
Manager calls.

## Create the secret

Store the Splunk Observability Cloud access token as a secret string:

```shell
aws secretsmanager create-secret \
  --name splunk/observability/access-token \
  --secret-string "<splunk-access-token>" \
  --region "<aws-region>"
```

Use a secret name or ARN that matches your organization's naming and access
control standards. Do not use `X-SF-TOKEN` as the Lambda environment variable
name; `X-SF-TOKEN` is the HTTP header sent to Splunk Observability Cloud.

## Create a Collector configuration

Create a file named `collector-config.yaml` with the following content:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: "localhost:4317"
      http:
        endpoint: "localhost:4318"
  telemetryapi:
    types: [platform, function]

exporters:
  otlphttp/splunk:
    traces_endpoint: "https://ingest.${env:SPLUNK_REALM}.observability.splunkcloud.com:443/v2/trace/otlp"
    metrics_endpoint: "https://ingest.${env:SPLUNK_REALM}.observability.splunkcloud.com:443/v2/datapoint/otlp"
    logs_endpoint: "https://ingest.${env:SPLUNK_REALM}.observability.splunkcloud.com:443/v1/logs"
    headers:
      "X-SF-TOKEN": "${secretsmanager:splunk/observability/access-token}"

service:
  telemetry:
    logs:
      level: "error"
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlphttp/splunk]
    metrics:
      receivers: [otlp]
      exporters: [otlphttp/splunk]
    logs:
      receivers: [telemetryapi, otlp]
      exporters: [otlphttp/splunk]
```

This configuration keeps the local OTLP receiver, Lambda Telemetry API receiver,
and Splunk traces, metrics, and logs pipelines. The only token-specific value is
the `X-SF-TOKEN` header, which the Collector resolves from AWS Secrets Manager.

If your secret value is JSON, reference the JSON key after `#`:

```yaml
headers:
  "X-SF-TOKEN": "${secretsmanager:splunk/observability/otel#access_token}"
```

You can use a full secret ARN instead of a secret name:

```yaml
headers:
  "X-SF-TOKEN": "${secretsmanager:arn:aws:secretsmanager:<region>:<account-id>:secret:splunk/observability/access-token-abc123}"
```

## Upload the configuration to S3

Upload the Collector configuration to an S3 bucket that the Lambda execution
role can read:

```shell
aws s3 cp collector-config.yaml \
  s3://<bucket-name>/collector-config.yaml \
  --region "<aws-region>"
```

The Collector S3 configuration provider supports virtual-hosted-style S3 URIs:

```text
s3://<bucket-name>.s3.<aws-region>.amazonaws.com/collector-config.yaml
```

## Configure the Lambda function

Set `OPENTELEMETRY_COLLECTOR_CONFIG_URI` to the S3 URI and remove
`SPLUNK_ACCESS_TOKEN` from the Lambda environment variables:

```yaml
Environment:
  Variables:
    AWS_LAMBDA_EXEC_WRAPPER: /opt/nodejs-otel-handler
    SPLUNK_REALM: us1
    OPENTELEMETRY_COLLECTOR_CONFIG_URI: s3://<bucket-name>.s3.<aws-region>.amazonaws.com/collector-config.yaml
```

Use the wrapper for the Lambda runtime:

| Runtime | Wrapper |
| --- | --- |
| Java `RequestHandler` | `/opt/otel-handler` |
| Java `RequestStreamHandler` | `/opt/otel-stream-handler` |
| Java API Gateway proxy handler | `/opt/otel-proxy-handler` |
| Node.js | `/opt/nodejs-otel-handler` |
| Python | `/opt/otel-instrument` |

Keep the Splunk OpenTelemetry Collector layer attached to the function. If the
Collector layer is not attached, `OPENTELEMETRY_COLLECTOR_CONFIG_URI` is not used
by the local Collector.

## Grant IAM permissions

The Lambda execution role needs permission to read the S3 configuration object
and the secret.

For AWS SAM, you can use policy templates:

```yaml
Policies:
  - AWSLambdaBasicExecutionRole
  - S3ReadPolicy:
      BucketName: <bucket-name>
  - AWSSecretsManagerGetSecretValuePolicy:
      SecretArn: arn:aws:secretsmanager:<region>:<account-id>:secret:splunk/observability/access-token-*
```

Or use an explicit IAM statement:

```yaml
Policies:
  - AWSLambdaBasicExecutionRole
  - Statement:
      - Effect: Allow
        Action:
          - s3:GetObject
        Resource: arn:aws:s3:::<bucket-name>/collector-config.yaml
      - Effect: Allow
        Action:
          - secretsmanager:GetSecretValue
        Resource: arn:aws:secretsmanager:<region>:<account-id>:secret:splunk/observability/access-token-*
```

If the S3 object or secret uses a customer managed AWS KMS key, also grant
`kms:Decrypt` for that key.

## Validate the deployment

After deploying the function:

1. Invoke the Lambda function.
2. Check CloudWatch Logs for Collector startup errors.
3. Confirm traces, metrics, and logs arrive in Splunk Observability Cloud.
4. Confirm the Lambda environment no longer contains `SPLUNK_ACCESS_TOKEN`.
5. Check AWS CloudTrail or Secrets Manager metrics to confirm
   `GetSecretValue` is called by the Lambda execution role.

To test token rotation, update the secret value and start a new Lambda execution
environment. The Collector resolves the secret during initialization, so already
warm execution environments do not automatically reload a rotated token.

## Troubleshooting

If telemetry does not arrive:

- Verify that the function has the Splunk OpenTelemetry Collector layer.
- Verify that `OPENTELEMETRY_COLLECTOR_CONFIG_URI` points to the S3 object.
- Verify that the S3 URI uses the expected format:
  `s3://<bucket-name>.s3.<aws-region>.amazonaws.com/<key>`.
- Verify that the Lambda execution role has `s3:GetObject`.
- Verify that the Lambda execution role has `secretsmanager:GetSecretValue`.
- Verify that `SPLUNK_REALM` is set to the correct Splunk Observability Cloud
  realm.
- Verify that the secret value contains only the Splunk access token, or that
  the JSON key in the `${secretsmanager:...#key}` placeholder is correct.

Do not log the resolved access token while troubleshooting.

## Related OpenTelemetry references

- [OpenTelemetry Collector S3 configuration provider](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/confmap/provider/s3provider)
- [OpenTelemetry Collector AWS Secrets Manager provider](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/confmap/provider/secretsmanagerprovider)
- [OpenTelemetry Lambda Collector layer](https://github.com/open-telemetry/opentelemetry-lambda/tree/main/collector)
