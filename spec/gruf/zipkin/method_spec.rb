require 'spec_helper'

describe Gruf::Zipkin::Method do
  let(:active_call) { grpc_active_call }
  let(:signature) { 'get_thing' }
  let(:request) { grpc_request }

  let(:method) { described_class.new(active_call, signature, request) }

  describe '.request_class' do
    subject { method.request_class }
    it 'should return the class name of the passed request' do
      expect(subject).to eq 'ThingRequest'
    end
  end

  describe '.headers' do
    subject { method.headers }
    it 'should return a headers object' do
      expect(subject).to be_a(Gruf::Zipkin::Headers)
    end
  end
end
