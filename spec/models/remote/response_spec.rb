require 'spec_helper'

module Remote
  describe Response do
    let(:response) { double('Remote::Client', code: 200, body: { foo: 'bar' }.to_json) }
    let(:invalid_response) { double('Remote::Client', code: 200, body: 'OK') }

    it 'returns parsed response' do
      described_class.new(response).decode_json.should eq({ foo: 'bar' })
    end

    it 'returns nil when response is malformed' do
      described_class.new(invalid_response).decode_json.should be_nil
    end
  end
end
