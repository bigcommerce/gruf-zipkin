# frozen_string_literal: true

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
    # Intercepts calls to provide Zipkin tracing
    #
    class Interceptor < Gruf::Interceptors::ServerInterceptor
      ##
      # Handle the gruf around hook and trace sampled requests
      #
      def call(&block)
        # do this here to ensure the tracer is initialized before the trace block. Zipkin's library has poor OOE support
        tr = tracer

        trace = build_trace

        return yield unless trace&.sampled?

        result = nil
        ::ZipkinTracer::TraceContainer.with_trace_id(trace.trace_id) do
          result = trace.trace!(tr, &block)
        end
        result
      end

      private

      ##
      # @return [ZipkinTracer::Config]
      #
      def config
        @config ||= ::ZipkinTracer::Config.new(nil, { sampled_as_boolean: false }.merge(options)).freeze
      end

      ##
      # @return [Trace::ZipkinTracerBase]
      #
      def tracer
        @tracer ||= ::ZipkinTracer::TracerFactory.new.tracer(config)
      end

      ##
      # @return [Gruf::Zipkin::Trace]
      #
      def build_trace
        method = Gruf::Zipkin::Method.new(request.active_call, request.method_key, request.message)
        Gruf::Zipkin::Trace.new(method, request.service_key, options)
      rescue StandardError => e # catchall for zipkin failure
        Gruf.logger.error "Failed to build zipkin trace: #{e.message}"
        nil
      end
    end
  end
end
