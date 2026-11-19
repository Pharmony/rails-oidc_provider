# frozen_string_literal: true

require 'rails_helper'

describe 'Authentication Fetch', type: :request do
  def client
    OIDCProvider.clients.last
  end

  before do
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
  let(:redirect_uri) { client.redirect_uri }

  context 'without passing arguments' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations" }

    before { get url }

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with "client_id" missing' do
      expect(response.body).to eql('invalid_request :: "client_id" missing')
    end
  end

  context 'when passing client_id only' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=test" }

    before { get url }

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with "response_type" required.' do
      expect(response.body).to eql("invalid_request :: 'response_type' required.")
    end
  end

  context 'when passing an unsupported response_type' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=test&response_type=test" }

    before { get url }

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with unsupported_response_type :: The requested response type is not supported by the authorization server.' do
      expect(response.body).to eql('unsupported_response_type :: The requested response type is not supported by the authorization server.')
    end
  end

  context 'when passing an unknown client_id but a supported response_type only' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=test&response_type=code" }

    before { get url }

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with not a valid client' do
      expect(response.body).to eql('invalid_request :: not a valid client')
    end
  end

  context 'when passing a valid client_id and a supported response_type only while being authenticated' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code" }

    before { login_and_logout_with_warden { get url } }

    it 'returns a 302' do
      expect(response).to have_http_status(:found)
    end

    it 'redirects to the redirect_uri with a code' do
      expect(response.location).to match(/\A#{redirect_uri}\?code=[a-z0-9]+\z/)
    end
  end

  context 'when redirect_uri is an Array, when passing a valid client_id and a supported response_type while being authenticated but without a redirect_uri' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code" }

    before do
      OIDCProvider.configure do |config|
        config.add_client do
          name 'Test Client'
          identifier '0001'
          secret '27ffb'
          redirect_uri %w[https://oauth.appclient.fr/oidc-client/cb
                          http://localhost:3000/oidc/test]
        end
      end

      login_and_logout_with_warden { get url }
    end

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with invalid_request :: "redirect_uri" missing' do
      expect(response.body).to eql('invalid_request :: "redirect_uri" missing')
    end
  end

  context 'when passing a valid client_id, a supported response_type but wrong redirect_uri while being authenticated' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code&redirect_uri=http://another.domain/callback" }

    before { login_and_logout_with_warden { get url } }

    it 'returns a 302' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with "redirect_uri" mismatch' do
      expect(response.body).to eql('invalid_request :: "redirect_uri" mismatch')
    end
  end

  context 'when passing a valid client_id, a supported response_type and an empty redirect_uri' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code&redirect_uri=" }

    before { get url }

    it 'returns a 400' do
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with "redirect_uri" mismatch' do
      expect(response.body).to eql('invalid_request :: "redirect_uri" mismatch')
    end
  end

  context 'when passing a valid client_id, a supported response_type, a matching redirect_uri but not being authenticated' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}" }

    before { get url }

    it 'returns a 302' do
      expect(response).to have_http_status(:found)
    end

    it 'redirects to the application login page' do
      expect(response.location).to eql("#{one_test_server_url}/signin")
    end
  end

  context 'when passing a valid client_id, a supported response_type and a redirect_uri while being authenticated' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}" }

    before { login_and_logout_with_warden { get url } }

    it 'returns a 302' do
      expect(response).to have_http_status(:found)
    end

    it 'redirects to the redirect_uri with a code' do
      expect(response.location).to match(/\A#{redirect_uri}\?code=[a-z0-9]+\z/)
    end
  end
end
