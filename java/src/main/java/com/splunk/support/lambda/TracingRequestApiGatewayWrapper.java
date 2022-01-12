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

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import io.opentelemetry.context.propagation.TextMapSetter;
import java.util.HashMap;

public class TracingRequestApiGatewayWrapper
    extends io.opentelemetry.instrumentation.awslambda.v1_0.TracingRequestApiGatewayWrapper {

  @Override
  protected APIGatewayProxyResponseEvent doHandleRequest(
      APIGatewayProxyRequestEvent input, Context context) {

    APIGatewayProxyResponseEvent result = super.doHandleRequest(input, context);
    ServerTimingHeader.setHeaders(
        io.opentelemetry.context.Context.current(), result, HeadersSetter.INSTANCE);
    return result;
  }

  private static final class HeadersSetter implements TextMapSetter<APIGatewayProxyResponseEvent> {
    public static final HeadersSetter INSTANCE = new HeadersSetter();

    @Override
    public void set(APIGatewayProxyResponseEvent carrier, String key, String value) {
      if (carrier.getHeaders() == null) {
        carrier.setHeaders(new HashMap<>());
      }
      carrier.getHeaders().put(key, value);
    }
  }
}
