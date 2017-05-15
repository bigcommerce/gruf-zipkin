require 'spec_helper'

describe Gruf::Zipkin do
  describe 'version' do
    it 'should have a version' do
      expect(Gruf::Zipkin::VERSION).to be_a(String)
    end
  end
end
