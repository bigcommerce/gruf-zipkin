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
    class Hook < Gruf::Hooks::Base

      ##
      # Sets up the tracing hook
      #
      def setup
        @config = ::ZipkinTracer::Config.new(nil, options).freeze
        @tracer = ::ZipkinTracer::TracerFactory.new.tracer(@config)
      end

      ##
      # Handle the gruf around hook and trace sampled requests
      #
      # @param [Symbol] call_signature
      # @param [Object] request
      # @param [GRPC::ActiveCall] active_call
      #
      def around(call_signature, request, active_call, &block)
        trace = build_trace(call_signature, request, active_call)

        if trace.sampled?
          result = nil
          ::ZipkinTracer::TraceContainer.with_trace_id(trace.trace_id) do
            result = trace.trace!(@tracer, &block)
          end
        else
          result = yield
        end
        result
      end

      ##
      # @return [String]
      #
      def service_key
        service.class.name.underscore.gsub('/','.')
      end

      ##
      # @return [Hash]
      #
      def options
        @options.fetch(:zipkin, {})
      end

      private

      ##
      # @param [Symbol] call_signature
      # @param [Object] request
      # @param [GRPC::ActiveCall] active_call
      # @return [Gruf::Zipkin::Trace]
      #
      def build_trace(call_signature, request, active_call)
        method = Gruf::Zipkin::Method.new(active_call, call_signature, request)
        Gruf::Zipkin::Trace.new(method, service_key, options)
      end
    end
  end
end
