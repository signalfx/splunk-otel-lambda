#!/usr/bin/env ruby

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  c.use_all() # enables all instrumentation!
end

class ServerTimingHeader

  FALSE_VALUES = %w(false no 0).freeze

  def is_enabled?
    value = ENV.fetch('SPLUNK_TRACE_RESPONSE_HEADER_ENABLED', 'true').to_s.downcase
    return false if FALSE_VALUES.include?(value)
    return true
  end

  def is_api_gateway_response?(response)
    response.respond_to?(:key) && response.key?(:body) && response.key?(:statusCode)
  end

  def append_header(headers, header, value)
    if !headers.key?(header)
      headers[header] = value
      return
    end
    # append to existing
    values = headers[header]
    if values.kind_of(Array)
      values.push(value)
    elsif values.kind_of(String)
      headers[header] = "#{values}, #{value}"
    end
  end

  def server_timing_header_value(span)

    span_context = span.context
    trace_id = span_context.hex_trace_id
    span_id = span_context.hex_span_id
    sampled = span_context.trace_flags.sampled?
    flags = sampled ? '01' : '00'

    "traceparent;desc=\"00-#{trace_id}-#{span_id}-#{flags}\""
  end

  def set_for_response(response:, span:)

    if !is_api_gateway_response?(response) || !is_enabled? || !span.context.valid?
      return
    end

    if !response["headers"]
      response["headers"] = {}
    end

    append_header(response["headers"], 'Access-Control-Expose-Headers', 'Server-Timing')
    append_header(response["headers"], 'Server-Timing', server_timing_header_value(span))
  end
end

class OriginalHandler
  attr_reader :handler_file, :original_handler

  def initialize
    @original_handler = ENV.fetch("ORIG_HANDLER")
    original_handler_parts = original_handler.split('.')
    if original_handler_parts.size == 2
      @handler_file, @handler_method = original_handler_parts
    elsif original_handler_parts.size == 3
      @handler_file, @handler_class, @handler_method = original_handler_parts
    else
      raise ArgumentError.new("Invalid handler #{original_handler}, must be of form FILENAME.METHOD or FILENAME.CLASS.METHOD.")
    end
  end

  def call_original_handler(request:, context:)
    arguments = {
        event: request,
        context: context
    }
    if @handler_class
      response = Kernel.const_get(@handler_class).send(@handler_method, arguments)
    else
      response = __send__(@handler_method, arguments)
    end
    response
  end
end

class OtelWrapper

  def initialize
    @flush_timeout = ENV.fetch('OTEL_INSTRUMENTATION_AWS_LAMBDA_FLUSH_TIMEOUT', 30000)
    @tracer_provider = OpenTelemetry.tracer_provider
    @tracer = @tracer_provider.tracer('OpenTelemetry::Instrumentation::AWS::Lambda')
    @lambda_handler = OriginalHandler.new()
    @server_timing_header = ServerTimingHeader.new()
    require @lambda_handler.handler_file
  end

  def get_attributes(context)
    {
      OpenTelemetry::SemanticConventions::Resource::FAAS_ID => context.invoked_function_arn,
      OpenTelemetry::SemanticConventions::Trace::FAAS_EXECUTION => context.aws_request_id
    }
  end

  def extract_parent_context(event)
    headers = {}
    if event.respond_to?(:fetch)
      headers = event.fetch("headers", {})
    end
    OpenTelemetry.propagation.extract(
      headers,
      getter: OpenTelemetry::Context::Propagation.text_map_getter
    )
  end

  def flush
    if @tracer_provider.respond_to?(:force_flush)
      @tracer_provider.force_flush(timeout: @flush_timeout)
    else
      puts "Error! No force_flush method available for TracerProvider implementation."
    end
  end

  def call_wrapped(event:, context:)

    # Extract context from request headers
    parent_context = extract_parent_context(event)
    span_attributes = get_attributes(context)

    OpenTelemetry::Context.with_current(parent_context) do
      # Span kind MUST be `:server` for a HTTP server span
      span = @tracer.start_span(
          @lambda_handler.original_handler,
          attributes: span_attributes,
          kind: :server
      )
      OpenTelemetry::Trace.with_span(span) do |span, context|
        response = @lambda_handler.call_original_handler(
            request: event,
            context: context
        )
        @server_timing_header.set_for_response(response: response, span: span)
        response
      end
    rescue Exception => e
      span&.record_exception(e)
      span&.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
      raise e
    ensure
      span&.finish
      flush
    end
  end
end

def otel_wrapper(event:, context:)
  otel_wrapper = OtelWrapper.new()
  otel_wrapper.call_wrapped(event: event, context: context)
end