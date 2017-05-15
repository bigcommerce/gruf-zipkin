# Copyright 2017, Bigcommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
# 3. Neither the name of BigCommerce Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
