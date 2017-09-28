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

describe Gruf::Zipkin::Interceptor do
  let(:service) { ThingService.new }
  let(:options) { {} }
  let(:signature) { 'get_thing' }
  let(:active_call) { grpc_active_call }
  let(:request) do
    double(
      :request,
      method_key: signature,
      service: ThingService,
      rpc_desc: nil,
      active_call: active_call,
      message: grpc_request
    )
  end
  let(:errors) { Gruf::Error.new }
  let(:interceptor) { described_class.new(request, errors, options.merge(sampled_as_boolean: false)) }

  before do
    allow(::Trace::Endpoint).to receive(:local_endpoint).and_return(nil)
  end

  describe '.call' do
    let(:trace) { grpc_trace }
    let(:sampled) { true }
    subject { interceptor.call { true } }

    before do
      allow(interceptor).to receive(:build_trace).and_return(trace)
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
