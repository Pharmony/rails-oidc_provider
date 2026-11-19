# frozen_string_literal: true

require 'rails_helper'

describe 'User Infos', type: :request do
  def client
    OIDCProvider.clients.last
  end

  context 'without being logged in' do
    let(:url) { "#{one_test_server_url}/accounts/oauth/user_info" }

    before { get url }

    it 'returns a 401' do
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with "client_id" missing' do
      expect(response.body).to eql(JSON.generate({ error: 'unauthorized' }))
    end
  end

  context 'when being logged in with an access_token' do
    def create_token_url(code)
      "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client.identifier}&grant_type=authorization_code&redirect_uri=#{client.redirect_uri}&client_secret=#{client.secret}&code=#{code}"
    end

    def scopes
      ERB::Util.url_encode(%w[openid profile email].join(' '))
    end

    def user
      @user ||= {
        email: "user-#{SecureRandom.hex(4)}@example.com",
        first_name: 'Jane',
        last_name: 'Doe'
      }
    end

    before(:all) do
      OIDCProvider.configure do |config|
        config.add_client do
          name 'Test Client'
          identifier '0001'
          secret '27ffb'
          redirect_uri 'https://oauth.appclient.fr/oidc-client/cb'
        end

        config.add_scope OIDCProvider::Scopes::Email do |user|
          email user.email
          email_verified true
        end

        config.add_scope OIDCProvider::Scopes::Profile do |user|
          name [user.first_name, user.last_name].join(' ')
          given_name user.first_name
          family_name user.last_name
        end
      end

      nonce = SecureRandom.hex(4)

      login_and_logout_with_warden(user) do
        # Create an authorization code
        get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{client.redirect_uri}&scope=#{scopes}&nonce=#{nonce}"

        authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

        # Create an access_token from the authorization code
        post create_token_url(authorization_code)

        access_token = JSON.parse(response.body)['access_token']

        # Fetch User information using the access_token
        get "#{one_test_server_url}/accounts/oauth/user_info", headers: {
          Authorization: "bearer #{access_token}"
        }
      end
    end

    it 'returns a 200' do
      expect(response).to have_http_status(:ok)
    end

    it "responds with a name containing the user's fullname" do
      expect(JSON.parse(response.body)).to include('name' => "#{user[:first_name]} #{user[:last_name]}")
    end

    it "responds with a given_name containing the user's first_name" do
      expect(JSON.parse(response.body)).to include('given_name' => user[:first_name])
    end

    it "responds with a family_name containing the user's last_name" do
      expect(JSON.parse(response.body)).to include('family_name' => user[:last_name])
    end

    it "responds with a email containing the user's email" do
      expect(JSON.parse(response.body)).to include('email' => user[:email])
    end

    it 'responds with a email_verified being true' do
      expect(JSON.parse(response.body)).to include('email_verified' => true)
    end
  end
end
