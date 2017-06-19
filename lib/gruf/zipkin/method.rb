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
    # Represents a Gruf gRPC method call
    #
    class Method
      attr_reader :active_call, :signature, :request

      ##
      # @param [GRPC::ActiveCall] active_call The gRPC ActiveCall object for this method
      # @param [String|Symbol] signature The method signature being called
      # @param [Object] request The gRPC request object being used
      #
      def initialize(active_call, signature, request)
        @active_call = active_call
        @signature = signature.to_s.gsub('_without_intercept', '')
        @request = request
      end

      ##
      # @return [Gruf::Zipkin::Headers]
      #
      def headers
        @headers ||= Gruf::Zipkin::Headers.new(@active_call)
      end

      ##
      # @return [String]
      #
      def request_class
        @request.class.to_s
      end
    end
  end
end
