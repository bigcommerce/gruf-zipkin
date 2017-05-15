require 'spec_helper'

describe Gruf::Zipkin::Trace do
  let(:metadata) { {} }
  let(:method) { grpc_method(metadata: metadata) }
  let(:options) { {} }
  let(:trace) { described_class.new(method, 'thing_service', options)}
  
  describe '.trace_id' do
    subject { trace.trace_id }

    context 'with no headers' do
      it 'should return a new trace id' do
        expect_any_instance_of(::ZipkinTracer::TraceGenerator).to receive(:next_trace_id).and_call_original
        expect(subject).to be_a(::Trace::TraceId)
      end
    end

    context 'with the trace_id and span_id headers' do
      let(:metadata) { {
        'X-B3-SpanId' => rand(2**64),
        'X-B3-TraceId' => rand(2**64),
      } }

      it 'should return a trace ID built from the headers' do
        expect(subject).to be_a(::Trace::TraceId)
        expect(subject.span_id.to_i).to eq ::Trace::SpanId.from_value(metadata['X-B3-SpanId']).to_i
        expect(subject.trace_id.to_i).to eq ::Trace::SpanId.from_value(metadata['X-B3-TraceId']).to_i
      end

      context 'with the required and optional headers' do
        let(:metadata) { {
            'X-B3-SpanId' => rand(2**64),
            'X-B3-TraceId' => rand(2**64),
            'X-B3-ParentSpanId' => rand(2**64),
            'X-B3-Sampled' => '1',
            'X-B3-Flags' => '1',
        } }
        it 'should return a trace ID built from those headers' do
          expect(subject).to be_a(::Trace::TraceId)
          expect(subject.span_id.to_i).to eq ::Trace::SpanId.from_value(metadata['X-B3-SpanId']).to_i
          expect(subject.trace_id.to_i).to eq ::Trace::SpanId.from_value(metadata['X-B3-TraceId']).to_i
          expect(subject.parent_id.to_i).to eq ::Trace::SpanId.from_value(metadata['X-B3-ParentSpanId']).to_i
          expect(subject.sampled).to eq metadata['X-B3-Sampled']
          expect(subject.flags).to eq metadata['X-B3-Flags']
        end
      end
    end

    context 'with only the trace_id header' do
      let(:metadata) { {
          'X-B3-TraceId' => rand(2**64),
      } }

      it 'should ignore it and build a new span' do
        expect_any_instance_of(::ZipkinTracer::TraceGenerator).to receive(:next_trace_id).and_call_original
        expect(subject).to be_a(::Trace::TraceId)
        expect(subject.trace_id.to_i).to_not eq ::Trace::SpanId.from_value(metadata['X-B3-TraceId']).to_i
      end
    end

    context 'with only the span_id header' do
      let(:metadata) { {
          'X-B3-SpanId' => rand(2**64),
      } }

      it 'should ignore it and build a new span' do
        expect_any_instance_of(::ZipkinTracer::TraceGenerator).to receive(:next_trace_id).and_call_original
        expect(subject).to be_a(::Trace::TraceId)
        expect(subject.trace_id.to_i).to_not eq ::Trace::SpanId.from_value(metadata['X-B3-SpanId']).to_i
      end
    end
  end

  describe '.sampled?' do
    subject { trace.sampled? }

    [1, '1', true, 'true'].each do |v|
      context "when the X-B3-Sampled header is passed with value #{v}" do
        let(:metadata) { {
            'X-B3-Sampled' => v,
        } }

        it 'should return true' do
          expect(subject).to be_truthy
        end
      end
    end

    [0, '0', false, 'false'].each do |v|
      context "when the X-B3-Sampled header is passed with value #{v}" do
        let(:metadata) { {
            'X-B3-Sampled' => v,
        } }

        it 'should return false' do
          expect(subject).to be_falsey
        end
      end
    end

    context 'when the X-B3-Sampled header is an empty string' do
      let(:expected_val) { rand(2) }
      let(:metadata) { {
          'X-B3-Sampled' => '',
      } }

      it 'should fallback to the sample rate' do
        expect(trace.trace_id).to receive(:sampled?).and_return(expected_val)
        expect(subject).to eq expected_val
      end
    end

    context 'when the X-B3-Sampled header is not passed' do
      let(:expected_val) { rand(2) }

      it 'should fallback to the sample rate' do
        expect(trace.trace_id).to receive(:sampled?).and_return(expected_val)
        expect(subject).to eq expected_val
      end
    end
  end

  describe '.span_prefix' do
    subject { trace.span_prefix }

    context 'when a span prefix is passed' do
      let(:options) { { span_prefix: 'abc' } }

      it 'should append the prefix and a .' do
        expect(subject).to eq 'abc.'
      end
    end

    context 'when no span prefix is passed' do
      it 'should return blank' do
        expect(subject).to eq ''
      end
    end
  end

  describe '.component' do
    subject { trace.component }

    context 'with a span prefix' do
      let(:options) { { span_prefix: 'abc' } }

      it 'should return the service key and the method signature concatenated with a . and prefixed' do
        expect(subject).to eq 'abc.thing_service.get_thing'
      end
    end

    context 'with no span prefix' do
      it 'should return the service key and the method signature concatenated with a .' do
        expect(subject).to eq 'thing_service.get_thing'
      end
    end
  end
end
