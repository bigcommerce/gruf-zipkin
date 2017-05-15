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
