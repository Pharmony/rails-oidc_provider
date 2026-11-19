# frozen_string_literal: true

require 'rails_helper'

describe 'Authentication Claims', type: :request do
  def build_claims_from(id_token: nil, userinfo: nil)
    claims = {}

    claims[:id_token] = id_token if id_token
    claims[:userinfo] = userinfo if userinfo

    ERB::Util.url_encode(claims.to_json)
  end

  def client
    OIDCProvider.clients.last
  end

  def create_token_url(code)
    "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client.identifier}&grant_type=authorization_code&redirect_uri=#{client.redirect_uri}&client_secret=#{client.secret}&code=#{code}"
  end

  def decoded_id_token
    id_token = response.parsed_body['id_token']
    JSON::JWT.decode(id_token, OIDCProvider::IdToken.public_jwk)
  end

  before do
    OIDCProvider.clients = []

    OIDCProvider.configure do |config|
      config.add_scope OIDCProvider::Scopes::Email do |user|
        email user.email
        email_verified true
      end

      config.add_scope OIDCProvider::Scopes::Profile do |user|
        name [user.first_name, user.last_name].join(' ')
      end

      config.add_client do
        name 'Test Client'
        identifier '0001'
        secret '27ffb'
        redirect_uri 'https://oauth.appclient.fr/oidc-client/cb'
      end
    end
  end

  let(:nonce) { SecureRandom.hex(4) }

  context 'when requesting an invalid claim (not a JSON)' do
    let(:claims) { 'test => false' }
    let(:scopes) { ERB::Util.url_encode(%w[openid].join(' ')) }

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&claims=#{claims}&nonce=#{nonce}"
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with "claims" invalid' do
      expect(response.body).to eql('invalid_request :: claims just be a JSON')
    end
  end

  context 'when requesting an invalid claim (empty JSON)' do
    let(:claims) { ERB::Util.url_encode({}.to_json) }
    let(:scopes) { ERB::Util.url_encode(%w[openid].join(' ')) }

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&claims=#{claims}&nonce=#{nonce}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        post create_token_url(authorization_code)
      end
    end

    it 'returns a 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'responds with an id_token' do
      expect(response.body).to match(/"id_token":"[A-Za-z0-9\-_.]+"/)
    end
  end

  context 'when requesting an invalid claim (malformed JSON)' do
    let(:claims) { ERB::Util.url_encode({ id_token: %w[email name] }.to_json) }
    let(:scopes) { ERB::Util.url_encode(%w[openid profile email].join(' ')) }

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&claims=#{claims}&nonce=#{nonce}"
      end
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with "claims" invalid' do
      expect(response.body).to eql('invalid_request :: invalid claims format')
    end
  end

  context 'when requesting an unknown claim' do
    let(:claims) { build_claims_from(id_token: { unknown: nil }) }
    let(:scopes) { ERB::Util.url_encode(%w[openid profile email].join(' ')) }

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&claims=#{claims}&nonce=#{nonce}"

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
      expect(decoded_id_token).to include('aud' => client.identifier)
    end

    it 'responds with an id_token containing the issuer URL as iss' do
      expect(decoded_id_token).to include('iss' => one_test_server_url)
    end

    it 'responds with an id_token containing the nonce as nonce' do
      expect(decoded_id_token).to include('nonce' => nonce)
    end

    it 'responds with an id_token without the "unknown" claim' do
      expect(decoded_id_token.keys).not_to include('unknown')
    end
  end

  context 'when requesting the "email" claim in the id_token without requesting the "email" scope' do
    let(:claims) { build_claims_from(id_token: { email: nil }) }
    let(:scopes) { ERB::Util.url_encode(%w[openid profile].join(' ')) }

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&claims=#{claims}&nonce=#{nonce}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        post create_token_url(authorization_code)
      end
    end

    it 'returns a 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'responds with an id_token' do
      expect(response.body).to match(/"id_token":"[A-Za-z0-9\-_.]+"/)
    end

    it 'responds with an id_token containing the client_it as aud' do
      expect(decoded_id_token).to include('aud' => client.identifier)
    end

    it 'responds with an id_token containing the issuer URL as iss' do
      expect(decoded_id_token).to include('iss' => one_test_server_url)
    end

    it 'responds with an id_token containing the nonce as nonce' do
      expect(decoded_id_token).to include('nonce' => nonce)
    end

    it 'responds with an id_token without the "email" claim' do
      expect(decoded_id_token.keys).not_to include('email')
    end
  end

  context 'when requesting the "email" claim in the id_token and requesting the "email" scope' do
    let(:claims) { build_claims_from(id_token: { email: nil }) }
    let(:scopes) { ERB::Util.url_encode(%w[openid profile email].join(' ')) }

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&claims=#{claims}&nonce=#{nonce}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        post create_token_url(authorization_code)
      end
    end

    it 'returns a 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'responds with an id_token' do
      expect(response.body).to match(/"id_token":"[A-Za-z0-9\-_.]+"/)
    end

    it 'responds with an id_token containing the client_it as aud' do
      expect(decoded_id_token).to include('aud' => client.identifier)
    end

    it 'responds with an id_token containing the issuer URL as iss' do
      expect(decoded_id_token).to include('iss' => one_test_server_url)
    end

    it 'responds with an id_token containing the nonce as nonce' do
      expect(decoded_id_token).to include('nonce' => nonce)
    end

    it 'responds with an id_token containing the "email" claim' do
      expect(decoded_id_token.keys).to include('email')
    end
  end

  context 'when requesting a claim with a given value' do
    let(:claims) { build_claims_from(id_token: { name: 'Guillaume Briat' }) }
    let(:scopes) { ERB::Util.url_encode(%w[openid profile].join(' ')) }

    before do
      login_and_logout_with_warden do
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&claims=#{claims}&nonce=#{nonce}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        post create_token_url(authorization_code)
      end
    end

    it 'returns a 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'responds with an id_token' do
      expect(response.body).to match(/"id_token":"[A-Za-z0-9\-_.]+"/)
    end

    it 'responds with an id_token containing the client_it as aud' do
      expect(decoded_id_token).to include('aud' => client.identifier)
    end

    it 'responds with an id_token containing the issuer URL as iss' do
      expect(decoded_id_token).to include('iss' => one_test_server_url)
    end

    it 'responds with an id_token containing the nonce as nonce' do
      expect(decoded_id_token).to include('nonce' => nonce)
    end

    it 'responds with an id_token containing the "email" claim' do
      expect(decoded_id_token).to include(name: 'Guillaume Briat')
    end
  end
end
