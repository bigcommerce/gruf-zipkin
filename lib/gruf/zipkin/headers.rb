module Gruf
  module Zipkin
    ##
    # Abstraction accessor class for B3 propagation headers across GRPC ActiveCall objects
    #
    class Headers
      attr_reader :active_call

      ##
      # @property [Hash<Symbol|Array<String>>] Hash mapping of metadata keys
      #
      ZIPKIN_KEYS = {
          parent_span_id: %w(x-b3-parentspanid X-B3-ParentSpanId HTTP_X_B3_PARENTSPANID),
          span_id: %w(x-b3-spanid X-B3-SpanId HTTP_X_B3_SPANID),
          trace_id: %w(x-b3-traceid X-B3-TraceId HTTP_X_B3_TRACEID),
          sampled: %w(x-b3-sampled X-B3-Sampled HTTP_X_B3_SAMPLED),
          flags: %w(x-b3-flags X-B3-Flags HTTP_X_B3_FLAGS)
      }.freeze

      ##
      # @param [GRPC::ActiveCall] active_call
      #
      def initialize(active_call)
        @active_call = active_call
      end

      ##
      # Return a B3 propagation header if present
      #
      # @param [Symbol] key
      # @return [String|NilClass]
      #
      def value(key)
        return nil unless ZIPKIN_KEYS.key?(key)
        ZIPKIN_KEYS[key].each do |k|
          return @active_call.metadata[k] if @active_call.metadata.key?(k)
        end
        nil
      end
    end
  end
end
