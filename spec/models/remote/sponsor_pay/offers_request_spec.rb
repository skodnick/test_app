require 'spec_helper'

module Remote::SponsorPay
  describe OffersRequest do
    let(:uid) { 'player1' }
    let(:pub0) { 'campaign2' }
    let(:api_key) { SponsorPaySettings.api_key }

    describe 'validations' do
      it 'valid when only uid provided' do
        described_class.new(uid).should be_valid
      end
      it 'invalid when page is not numeric' do
        described_class.new(uid, '', 'foo').should_not be_valid
      end
      it 'valid when uid and pub0 provided' do
        described_class.new(uid, pub0).should be_valid
      end
      it 'valid when uid, pub and page provided' do
        described_class.new(uid, pub0, 1).should be_valid
      end
    end

    describe '#params' do
      let(:app_params) do
        { uid: uid, pub0: pub0, page: 1, timestamp: Time.zone.now.to_i }.merge(SponsorPaySettings.app_params.symbolize_keys)
      end
      before { Timecop.freeze(Time.zone.now) }

      subject { Rack::Utils.parse_nested_query(described_class.new(uid, pub0).params).symbolize_keys }

      it 'includes parameters alphabetically sorted' do
        subject.except(:hashkey).keys.should eq app_params.keys.sort
      end

      it 'includes hashkey param' do
        subject.should include(:hashkey)
      end

      it 'builds correct hashkey' do
        hashkey = Digest::SHA1.hexdigest("#{CGI.unescape(app_params.to_query)}&#{api_key}")
        subject[:hashkey].should eq hashkey
      end
    end

    describe '#perform' do
      let(:url) { SponsorPaySettings.url }

      let(:response) do
        { code: 'OK',
          offers: [
            { title: 'Tap Fish',
              offer_id: 13554,
              teaser: ' Download and START ',
              required_actions: 'Download and START',
              link: 'http://iframe.sponsorpay.com/mbrowser?appid=157&lpid=11387&uid=player1',
              offer_types: [ { offer_type_id: '101', readable: 'Download' },
                             { offer_type_id: '112', readable:  'Free' } ],
              thumbnail: {
                lowres: 'http://cdn.sponsorpay.com/assets/1808/icon175x175-2_square_60.png',
                hires: 'http://cdn.sponsorpay.com/assets/1808/icon175x175-2_square_175.png' },
              payout: '90',
              time_to_payout: { amount: '1800', readable: '30 minutes' }
            }
          ]
        }
      end

      def stub_api_request(response_body, api_key)
        body = response_body.is_a?(String) ? response_body : response_body.to_json
        signature = Digest::SHA1.hexdigest(body + api_key)
        stub_request(:get, /#{url}/).
          to_return(body: body, headers: { 'X-Sponsorpay-Response-Signature' => signature })
      end

      context 'succesfully fetches offers from the API' do
        before { stub_api_request(response, api_key) }

        subject { described_class.perform(uid) }

        it 'returns offers' do
          subject[:offers].should be
        end

        it 'returns offers as Array' do
          subject[:offers].should be_kind_of(Array)
        end

        it 'returns offers as instances of presenter' do
          subject[:offers].first.should be_kind_of(Presenters::SponsorPay::Offer)
        end

        it 'returns response_time' do
          subject[:response_time].should be
        end
      end

      context 'incorrect signature' do
        subject { described_class.perform(uid) }

        before do
          stub_request(:get, /#{url}/)
            .to_return(body: response.to_json, headers: { 'X-Sponsorpay-Response-Signature' => 'foobar' })
        end

        it 'does not contain any offers' do
          subject[:offers].should_not be
        end

        it 'contains readable error message' do
          subject[:error].should eq 'Signature error'
        end
      end

      context 'malformed response' do
        subject { described_class.perform(uid) }

        before do
          stub_api_request('foo', api_key)
        end

        it 'does not contain any offers' do
          subject[:offers].should_not be
        end

        it 'contains readable error message' do
          subject[:error].should eq 'Malformed response body'
        end
      end

      { 'ERROR_INVALID_PAGE'          => 400,
        'ERROR_INVALID_HASHKEY'       => 401,
        'ERROR_INTERNAL_SERVER_ERROR' => 500 }.each do |code, status|

        context "#{code}" do
          subject { described_class.perform(uid, pub0) }

          before do
            stub_request(:get, /#{url}/)
              .to_return(status: status, body: { code: code, message: 'description' }.to_json)
          end

          it 'does not contain any offers' do
            subject[:offers].should_not be
          end

          it 'contains readable error message' do
            subject[:error].should match(/#{code}/)
          end
        end
      end
    end
  end
end
