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
