
class ThingRequest; end
class ThingService; end

module Gruf
  module Zipkin
    module SpecHelpers

      def grpc_method(metadata: {}, signature: 'get_thing')
        active_call = grpc_active_call(metadata: metadata)
        signature = signature
        request = grpc_request
        ::Gruf::Zipkin::Method.new(active_call, signature, request)
      end

      def grpc_active_call(metadata: {}, output_metadata: {})
        double(:active_call, metadata: metadata, output_metadata: output_metadata)
      end

      def grpc_trace(metadata: {}, service_key: 'thing_service', signature: 'get_thing', options: {})
        method = grpc_method(metadata: metadata, signature: signature)
        Gruf::Zipkin::Trace.new(method, service_key, options)
      end

      def grpc_request
        ThingRequest.new
      end
    end
  end
end
