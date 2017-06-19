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
require 'spec_helper'

describe Gruf::Zipkin::Hook do
  let(:service) { ThingService.new }
  let(:options) { {} }
  let(:signature) { 'get_thing' }
  let(:request) { grpc_request }
  let(:active_call) { grpc_active_call }
  let(:hook) { described_class.new(service, { zipkin: options.merge(sampled_as_boolean: false) }) }

  before do
    allow(::Trace::Endpoint).to receive(:local_endpoint).and_return(nil)
  end

  describe '.service_key' do
    subject { hook.service_key }
    it 'should be the translated service class name' do
      expect(subject).to eq 'thing_service'
    end
  end

  describe '.options' do
    let(:options) { { abc: 'def' } }
    subject { hook.options }

    it 'should return zipkin options' do
      expect(subject).to eq options.merge(sampled_as_boolean: false)
    end
  end

  describe '.around' do
    let(:trace) { grpc_trace }
    let(:sampled) { true }
    subject { hook.around(trace.method.signature, trace.method.request, trace.method.active_call) { true } }

    before do
      allow(hook).to receive(:build_trace).and_return(trace)
      allow(trace).to receive(:sampled?).and_return(sampled)
    end

    context 'when the trace is sampled' do
      it 'should trace the request' do
        expect(ZipkinTracer::TraceContainer).to receive(:with_trace_id).with(trace.trace_id).and_call_original
        expect(trace).to receive(:trace!)
        subject
      end
    end

    context 'when the trace is not sampled' do
      let(:sampled) { false }
      it 'should not trace the request' do
        expect(ZipkinTracer::TraceContainer).to_not receive(:with_trace_id)
        subject
      end
    end
  end
end
