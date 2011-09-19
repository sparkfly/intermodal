require 'spec_helper'

describe Intermodal::Rack::Auth do
  include SpecHelpers::Rack
  include SpecHelpers::AuthenticationSchema
  use_authentication_schema

  let(:application) { Intermodal::Rack::Auth }

  context 'when successfully authenticating' do
    let(:http_headers) { {
      'X-Auth-Identity' => access_credential.identity,
      'X-Auth-Key' => access_credential.key } }

    request :get, '/' do
      expects_status(204)

      it 'should respond with a valid X-Auth-Token header' do
        response_headers.should be_include('X-Auth-Token')
        AccessToken.authenticate!(response_headers['X-Auth-Token']).should eql(account)
      end

    end
  end

  context 'with invalid authentication credentials' do
    let(:http_headers)  { {
      'X-Auth-Identity' => 'no identity',
      'X-Auth-Key' => 'no key' } }

    request :get, '/' do
      expects_status(401)
    end
  end

  pending 'with invalid access token'

end
