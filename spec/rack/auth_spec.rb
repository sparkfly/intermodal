require 'spec_helper'

describe Intermodal::Rack::Auth do
  include Intermodal::RSpec::Rack
  include SpecHelpers::Application

  let(:application) { Intermodal::Rack::Auth }

  context 'when successfully authenticating' do
    let(:http_headers) { {
      'X-Auth-Identity' => access_credential.identity,
      'X-Auth-Key' => access_credential.key } }

    request :get, '/' do
      expects_status(204)
      expects_empty_body # Make sure returned body responds to #each (String has no #each in 1.9)

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
      expects_empty_body # Make sure returned body responds to #each (String has no #each in 1.9)
    end
  end

  context 'with invalid access token' do
    let(:x_access_token) { 'invalid_key' }
    let(:delete_access_token) { AccessToken::REDIS.del("auth:#{x_access_token}") }
    let(:http_headers) do
      delete_access_token
      { 'X-Access-Token' => x_access_token }
    end

    request :get, '/' do
      expects_status(401)
      expects_empty_body # Make sure returned body responds to #each (String has no #each in 1.9)
    end
  end

end
