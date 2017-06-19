# coding: utf-8
# Copyright (c) 2017-present, BigCommerce Pty. Ltd. All rights reserved
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module Gruf
  module Zipkin
    ##
    # Represents a trace through Gruf and gRPC
    #
    class Trace
      attr_reader :method, :service_key

      METADATA_KEYS = {
        error: 'error',
        grpc: {
          method: 'grpc.method',
          request_class: 'grpc.request_class',
          error: 'grpc.error',
          error_code: 'grpc.error_code',
          error_class: 'grpc.error_class',
          success: 'grpc.success',
        }
      }.freeze

      ##
      # @param [Gruf::Zipkin::Method] method
      # @param [String|Symbol] service_key
      # @param [Hash] options
      #
      def initialize(method, service_key, options = {})
        @method = method
        @service_key = service_key.to_s
        @options = options
      end

      ##
      # Trace the request
      #
      # @param [::Trace::Tracer] The tracing service to use
      # @return [Object]
      #
      def trace!(tracer, &block)
        raise ArgumentError, 'no block given' unless block_given?
        # If for some reason we don't have a tracer, let's just proceed as normal
        # and not cause the request to fail
        unless tracer
          Gruf.logger.warn "Failed to log trace for #{method.request_class}.#{method.signature.classify} because Tracer was not found!" if Gruf.logger
          return block.call(method.request, method.active_call)
        end

        result = nil

        tracer.with_new_span(trace_id, component) do |span|
          span.record(::Trace::Annotation::SERVER_RECV)
          span.record_local_component(component)
          span.record_tag(METADATA_KEYS[:grpc][:method], method.signature.classify)
          span.record_tag(METADATA_KEYS[:grpc][:request_class], method.request_class)

          begin
            result = block.call(method.request, method.active_call)
            span.record(::Trace::Annotation::SERVER_SEND)
          rescue => e
            if e.is_a?(::GRPC::BadStatus)
              span.record_tag(METADATA_KEYS[:error], true)
              span.record_tag(METADATA_KEYS[:grpc][:error], true)
              span.record_tag(METADATA_KEYS[:grpc][:error_code], e.code.to_s)
              span.record_tag(METADATA_KEYS[:grpc][:error_class], e.class.to_s)
            end
            span.record(::Trace::Annotation::SERVER_SEND)
            tracer.end_span(span) # manually end here as the raise prevents this
            raise # passthrough, we just want the annotations
          end
        end
        result
      end


      ##
      # Memoize build of a new trace_id based on propagation headers, or generator if
      # no headers are present
      # 
      # @return [::Trace::TraceId]
      #
      def trace_id
        unless @trace_id
          tid = header_value(:trace_id)
          span_id = header_value(:span_id)
          # both trace ID and span ID are required for propagation
          if !tid.to_s.empty? && !span_id.to_s.empty?
            # we have a propagated trace, let's carry over the information
            parent_id = header_value(:parent_span_id)
            sampled = header_value(:sampled)
            flags = header_value(:flags)
            @trace_id = ::Trace::TraceId.new(tid, parent_id, span_id, sampled, flags)
          else
            # if trace_id/span_id are not present, generate a new trace
            @trace_id = ::ZipkinTracer::TraceGenerator.new.next_trace_id
          end
        end
        @trace_id
      end

      ##
      # Delegator to headers object to get value of a B3 header
      #
      # @param [Symbol] key
      # @return [String|NilClass]
      #
      def header_value(key)
        @method.headers.value(key)
      end

      ##
      # Returning whether or not this trace is sampled, which is based on either:the sample
      # 1) The X-B3-Sampled header, if present
      # 2) The sample rate set in the zipkin configuration
      # ...in that order.
      #
      # @return [Boolean]
      #
      def sampled?
        sampled = header_value(:sampled)
        if sampled && sampled.to_s != ''
          [1, '1', 'true', true].include?(sampled)
        else
          trace_id.sampled?
        end
      end

      ##
      # @return [String]
      #
      def component
        "#{span_prefix}#{@service_key}.#{@method.signature}"
      end

      ##
      # @return [String]
      #
      def span_prefix
        prefix = @options.fetch(:span_prefix, '').to_s
        prefix.empty? ? '' : "#{prefix}."
      end
    end
  end
end
