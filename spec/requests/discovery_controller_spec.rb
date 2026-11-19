# frozen_string_literal: true

require 'rails_helper'

describe 'OpenID Discovery', type: :request do
  before do
    OIDCProvider.configure do |_config|
      # resets scopes to openid only
    end
  end

  describe 'GET /.well-known/openid-configuration' do
    context 'without configured scopes' do
      before { get "#{test_server_url}/.well-known/openid-configuration" }

      it 'returns the OpenID configuration' do
        expect(JSON.parse(response.body).deep_symbolize_keys).to eql(
          {
            authorization_endpoint: "#{test_server_url}/accounts/oauth/authorizations",
            claims_parameter_supported: true,
            claims_supported: %w[iss sub aud nonce exp iat],
            end_session_endpoint: "#{test_server_url}/accounts/oauth/sessions/logout",
            grant_types_supported: ['authorization_code'],
            id_token_signing_alg_values_supported: ['RS256'],
            issuer: test_server_url,
            jwks_uri: "#{test_server_url}/accounts/oauth/jwks.json",
            response_types_supported: ['code'],
            scopes_supported: %w[openid],
            subject_types_supported: ['public'],
            token_endpoint: "#{test_server_url}/accounts/oauth/tokens",
            token_endpoint_auth_methods_supported: %w[client_secret_basic client_secret_post],
            userinfo_endpoint: "#{test_server_url}/accounts/oauth/user_info"
          }
        )
      end
    end

    context 'with all scopes configured' do
      before do
        OIDCProvider.configure do |config|
          config.add_scope OIDCProvider::Scopes::Profile do |user|
            name user.full_name
            given_name user.first_name
            family_name user.last_name
          end

          config.add_scope OIDCProvider::Scopes::Email do |user|
            email user.email
            email_verified false
          end
        end

        get "#{test_server_url}/.well-known/openid-configuration"
      end

      it 'returns the OpenID configuration' do
        expect(JSON.parse(response.body).deep_symbolize_keys).to eql(
          {
            authorization_endpoint: "#{test_server_url}/accounts/oauth/authorizations",
            claims_parameter_supported: true,
            claims_supported: %w[iss sub aud nonce exp iat name given_name family_name email email_verified],
            end_session_endpoint: "#{test_server_url}/accounts/oauth/sessions/logout",
            grant_types_supported: ['authorization_code'],
            id_token_signing_alg_values_supported: ['RS256'],
            issuer: test_server_url,
            jwks_uri: "#{test_server_url}/accounts/oauth/jwks.json",
            response_types_supported: ['code'],
            scopes_supported: %w[openid profile email],
            subject_types_supported: ['public'],
            token_endpoint: "#{test_server_url}/accounts/oauth/tokens",
            token_endpoint_auth_methods_supported: %w[client_secret_basic client_secret_post],
            userinfo_endpoint: "#{test_server_url}/accounts/oauth/user_info"
          }
        )
      end
    end
  end
end
