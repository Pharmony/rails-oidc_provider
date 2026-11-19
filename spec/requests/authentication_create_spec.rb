# frozen_string_literal: true

require 'rails_helper'

describe 'Authentication Create', type: :request do
  def client
    OIDCProvider.clients.last
  end

  before(:all) do
    OIDCProvider.configure do |config|
      config.add_client do
        name 'Test Client'
        identifier '0001'
        secret '27ffb'
        redirect_uri 'https://oauth.appclient.fr/oidc-client/cb'
      end
    end
  end

  let(:client_id) { client.identifier }
  let(:client_secret) { client.secret }
  let(:redirect_uri) { client.redirect_uri }

  context 'without passing arguments' do
    let(:create_token_url) { "#{one_test_server_url}/accounts/oauth/tokens" }
    let(:expected_hash) do
      {
        error: 'invalid_request',
        error_description: "'client_id', 'grant_type' required."
      }
    end

    before do
      login_and_logout_with_warden do
        post create_token_url
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with "redirect_uri" missing' do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  context 'when passing client_id and an invalid grant_type' do
    let(:create_token_url) do
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=test"
    end
    let(:expected_hash) do
      {
        error: 'unsupported_grant_type',
        error_description: 'The access grant included - its type or another attribute - is not supported by the authorization server.'
      }
    end

    before do
      login_and_logout_with_warden do
        post create_token_url
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with The access grant included - its type or another attribute - is not supported by the authorization server.' do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  # Supported-syntax but unsupported grant types must be rejected with an
  # OAuth error (RFC 6749 section 5.2) instead of an unhandled HTTP 500,
  # regardless of the client identifier presence.
  # (Strix run `one-stg-pharmony-eu_40d0`, finding `vuln-0002`,
  # GitLab work item pharmony/pharmony-one#68.)
  context 'when passing client_id and the password grant type' do
    let(:create_token_url) do
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=password&username=test&password=test"
    end
    let(:expected_hash) do
      {
        error: 'unsupported_grant_type',
        error_description: 'The access grant included - its type or another attribute - is not supported by the authorization server.'
      }
    end

    before do
      login_and_logout_with_warden do
        post create_token_url
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with an unsupported_grant_type error' do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  context 'when passing client_id and the client_credentials grant type' do
    let(:create_token_url) do
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=client_credentials"
    end
    let(:expected_hash) do
      {
        error: 'unsupported_grant_type',
        error_description: 'The access grant included - its type or another attribute - is not supported by the authorization server.'
      }
    end

    before do
      login_and_logout_with_warden do
        post create_token_url
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with an unsupported_grant_type error' do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  context 'when passing client_id and the refresh_token grant type' do
    let(:create_token_url) do
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=refresh_token&refresh_token=test"
    end
    let(:expected_hash) do
      {
        error: 'unsupported_grant_type',
        error_description: 'The access grant included - its type or another attribute - is not supported by the authorization server.'
      }
    end

    before do
      login_and_logout_with_warden do
        post create_token_url
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with an unsupported_grant_type error' do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  context 'when passing the password grant type without client_id' do
    let(:create_token_url) do
      "#{one_test_server_url}/accounts/oauth/tokens?grant_type=password&username=test&password=test"
    end
    let(:expected_hash) do
      {
        error: 'invalid_request',
        error_description: "'client_id' required."
      }
    end

    before do
      login_and_logout_with_warden do
        post create_token_url
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it "responds with a 'client_id' required error" do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  context 'when passing client_id and grant_type only' do
    let(:create_token_url) do
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=authorization_code"
    end
    let(:expected_hash) do
      {
        error: 'invalid_request',
        error_description: "'code' required."
      }
    end

    before do
      login_and_logout_with_warden do
        post create_token_url
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it "responds with 'code' required." do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  context 'when passing client_id, grant_type and code but without client secret' do
    def create_token_url(code)
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=authorization_code&redirect_uri=#{redirect_uri}&code=#{code}"
    end

    let(:expected_hash) do
      {
        error: 'invalid_client',
        error_description: <<~DESC.gsub("\n", ' ').gsub('  ', '').strip
          The client identifier provided is invalid, the client failed to authenticate,
          the client did not include its credentials, provided multiple client credentials,
          or used unsupported credentials type.
        DESC
      }
    end

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        post create_token_url(authorization_code)
      end
    end

    it 'returns a 401' do
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with an invalid_client error' do
      expect(response.body).to eql(JSON.generate(expected_hash))
    end
  end

  context 'when passing client_id, grant_type, code and client secret without scope and nonce' do
    let(:nonce) { SecureRandom.hex(4) }

    def create_token_url(code)
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=authorization_code&redirect_uri=#{redirect_uri}&client_secret=#{client_secret}&code=#{code}"
    end

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        post create_token_url(authorization_code)
      end
    end

    it 'returns a 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'responds with an access_token' do
      expect(response.body).to match(/"access_token":"[a-z0-9]+"/)
    end

    it 'responds with an token_type' do
      expect(response.body).to include('"token_type":"bearer"')
    end

    it 'responds with an expires_in' do
      expect(response.body).to match(/"expires_in":\d+/)
    end

    it "doesn't respond with an id_token" do
      expect(response.body).not_to match(/"id_token":"[A-Za-z0-9\-_.]+"/)
    end
  end

  context 'when passing client_id, grant_type, code and client secret' do
    let(:nonce) { SecureRandom.hex(4) }
    let(:scopes) { ERB::Util.url_encode(%w[openid profile email].join(' ')) }

    def create_token_url(code)
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client_id}&grant_type=authorization_code&redirect_uri=#{redirect_uri}&client_secret=#{client_secret}&code=#{code}"
    end

    def decoded_id_token
      id_token = response.parsed_body['id_token']
      JSON::JWT.decode(id_token, OIDCProvider::IdToken.public_jwk)
    end

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}&scope=#{scopes}&nonce=#{nonce}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        post create_token_url(authorization_code)
      end
    end

    it 'returns a 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'responds with an access_token' do
      expect(response.body).to match(/"access_token":"[a-z0-9]+"/)
    end

    it 'responds with an token_type' do
      expect(response.body).to include('"token_type":"bearer"')
    end

    it 'responds with an expires_in' do
      expect(response.body).to match(/"expires_in":\d+/)
    end

    it 'responds with an id_token' do
      expect(response.body).to match(/"id_token":"[A-Za-z0-9\-_.]+"/)
    end

    it 'responds with an id_token containing the client_it as aud' do
      expect(decoded_id_token).to include('aud' => client_id)
    end

    it 'responds with an id_token containing the issuer URL as iss' do
      expect(decoded_id_token).to include('iss' => one_test_server_url)
    end

    it 'responds with an id_token containing the nonce as nonce' do
      expect(decoded_id_token).to include('nonce' => nonce)
    end
  end
end
