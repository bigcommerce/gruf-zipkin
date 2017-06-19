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
require 'securerandom'

describe Gruf::Zipkin::Headers do
  let(:active_call) { grpc_active_call(metadata: metadata) }
  let(:metadata) { {} }
  let(:headers) { described_class.new(active_call) }

  describe '.value' do
    let(:val) { SecureRandom.uuid }

    described_class::ZIPKIN_KEYS.each do |name, keys|
      context "when checking for the #{name} header value" do
        subject { headers.value(name) }

        keys.each do |key|
          context "when the key #{key} is set" do
            let(:metadata) { { key.to_s => val } }

            it 'should return the value' do
              expect(subject).to eq val
            end
          end

          context "when the key #{key} is not set" do
            let(:metadata) { { "#{key}_nope" => val } }

            it 'should return nil' do
              expect(subject).to be_nil
            end
          end
        end
      end
    end
  end
end
