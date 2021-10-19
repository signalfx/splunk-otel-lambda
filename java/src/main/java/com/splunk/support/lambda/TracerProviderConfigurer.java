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

package com.splunk.support.lambda;

import com.google.auto.service.AutoService;
import io.opentelemetry.exporter.logging.LoggingSpanExporter;
import io.opentelemetry.sdk.autoconfigure.spi.ConfigProperties;
import io.opentelemetry.sdk.autoconfigure.spi.traces.SdkTracerProviderConfigurer;
import io.opentelemetry.sdk.trace.SdkTracerProviderBuilder;
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor;

@AutoService(SdkTracerProviderConfigurer.class)
public class TracerProviderConfigurer implements SdkTracerProviderConfigurer {

  private static final String OTEL_LAMBDA_LOG_LEVEL = "OTEL_LAMBDA_LOG_LEVEL";

  @Override
  public void configure(SdkTracerProviderBuilder tracerProviderBuilder, ConfigProperties config) {
    if ("DEBUG".equalsIgnoreCase(System.getenv(OTEL_LAMBDA_LOG_LEVEL))) {
      maybeEnableLoggingExporter(tracerProviderBuilder, config);
    }
  }

  private static void maybeEnableLoggingExporter(
      SdkTracerProviderBuilder builder, ConfigProperties config) {
    // don't install another instance if the user has already explicitly requested it.
    if (!loggingExporterIsAlreadyConfigured(config)) {
      builder.addSpanProcessor(SimpleSpanProcessor.create(new LoggingSpanExporter()));
    }
  }

  private static boolean loggingExporterIsAlreadyConfigured(ConfigProperties config) {
    return config.getList("OTEL_TRACES_EXPORTER").contains("logging");
  }
}
