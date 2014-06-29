require 'spec_helper'

module Remote
  describe Client do
    let(:query_params) { { key: 'value' } }
    let(:url) { "www.example.com/path_name?#{query_params.to_query}" }

    describe '#get with query params' do
      before do
        stub_request(:any, 'http://example.org/?foo=bar&qwe=baz').to_return(status: 200)
        described_class.get('http://example.org', query: { foo: 'bar', qwe: 'baz' } )
      end

      it 'sends the correct request' do
        a_request(:get, 'http://example.org/?foo=bar&qwe=baz').should have_been_made
      end
    end

    describe '#get' do
      before do
        stub_request(:any, url).to_return(status: 200)
        described_class.get(url)
      end

      it 'sends the corret request' do
        a_request(:get, url).should have_been_made
      end
    end

    describe 'erroneous answers' do
      shared_examples 'handling exceptions' do
        it 'ensures request has been made' do
          perform_request
          a_request(:get, url).should have_been_made
        end

        it 'does not have offers' do
          perform_request[:offers].should be_nil
        end

        it 'contains error' do
          perform_request[:error].should be
        end
      end

      subject { described_class.get(url) }

      describe 'bad request' do
        before { stub_request(:get, url).to_return(status: 400, body: 'Bad Request') }

        it_should_behave_like 'handling exceptions' do
          let(:perform_request) { subject }
        end
      end

      describe 'Errno::EHOSTUNREACH: No route to host' do
        before { stub_request(:get, url).to_raise(Errno::EHOSTUNREACH) }

        it_should_behave_like 'handling exceptions' do
          let(:perform_request) { subject }
        end
      end

      describe 'Errno::ECONNRESET: Connection reset by peer' do
        before { stub_request(:get, url).to_raise(Errno::ECONNRESET) }

        it_should_behave_like 'handling exceptions' do
          let(:perform_request) { subject }
        end
      end

      describe 'Errno::ECONNREFUSED: Connection refused - connect(2)' do
        before { stub_request(:get, url).to_raise(Errno::ECONNREFUSED) }

        it_should_behave_like 'handling exceptions' do
          let(:perform_request) { subject }
        end
      end

      describe 'request timeout' do
        before { stub_request(:get, url).to_return(status: 408, body: 'Request Timeout') }

        it_should_behave_like 'handling exceptions' do
          let(:perform_request) { subject }
        end
      end

      describe 'bad gateway' do
        before { stub_request(:get, url).to_return(status: 502, body: 'Bad Gateway') }

        it_should_behave_like 'handling exceptions' do
          let(:perform_request) { subject }
        end
      end
    end
  end
end
