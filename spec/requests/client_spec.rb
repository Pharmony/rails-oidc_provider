# frozen_string_literal: true

require 'rails_helper'

describe OIDCProvider::Client, type: :request do
  def client
    OIDCProvider.clients.last
  end

  def create_token_url(code, redirect_uri)
    "#{one_test_server_url}/accounts/oauth/tokens?client_id=#{client.identifier}&grant_type=authorization_code&redirect_uri=#{redirect_uri}&client_secret=#{client.secret}&code=#{code}"
  end

  def nonce
    SecureRandom.hex(4)
  end

  def user
    @user ||= {
      email: "user-#{SecureRandom.hex(4)}@example.com",
      first_name: 'Jane',
      last_name: 'Doe'
    }
  end

  before { OIDCProvider.configure {} } # rubocop:disable Lint/EmptyBlock

  context 'when calling add_client without any parameters' do
    it 'raises' do
      expect { OIDCProvider.add_client }.to raise_error(LocalJumpError, 'no block given')
    end
  end

  context 'when calling add_client with a blank block' do
    before do
      OIDCProvider.add_client {} # rubocop:disable Lint/EmptyBlock
    end

    it 'adds a client' do
      expect(OIDCProvider.clients.size).to eq 1
    end

    it 'clients contains one client with an `identifier` attribute being `nil`' do
      expect(OIDCProvider.clients.first.identifier).to be_nil
    end

    it 'clients contains one client with a `secret` attribute being `nil`' do
      expect(OIDCProvider.clients.first.secret).to be_nil
    end

    it 'clients contains one client with a nil `redirect_uri` attribute' do
      expect(OIDCProvider.clients.first.redirect_uri).to be_nil
    end

    it 'clients contains one client with a `name` attribute being `nil`' do
      expect(OIDCProvider.clients.first.name).to be_nil
    end
  end

  context 'when calling add_client with a block with all attributes' do
    before do
      OIDCProvider.configure do |config|
        config.add_client do
          name 'Test Client'
          identifier "client-#{OIDCProvider.clients.size + 1}"
          secret SecureRandom.hex(4)
          redirect_uri(rand(1..3).times.map { 'https://client.example.com' })
        end
      end
    end

    it 'adds a client' do
      expect(OIDCProvider.clients.size).to eq 1
    end

    it 'clients contains one client with a present `identifier` attribute' do
      expect(OIDCProvider.clients.first.identifier).to be_present
    end

    it 'clients contains one client with a present `secret` attribute' do
      expect(OIDCProvider.clients.first.secret).to be_present
    end

    it 'clients contains one client with a present `redirect_uri` attribute' do
      expect(OIDCProvider.clients.first.redirect_uri).to be_present
    end

    it 'clients contains one client with a present `name` attribute' do
      expect(OIDCProvider.clients.first.name).to be_present
    end
  end

  # when `redirect_uri` is a string is already tested in other spec files, so
  # here we are only testing when it is an Array.
  context 'when redirect_uri is an array' do
    before do
      OIDCProvider.configure do |config|
        config.add_scope OIDCProvider::Scopes::Email do |user|
          email user.email
          email_verified true
        end

        config.add_scope OIDCProvider::Scopes::Profile do |user|
          name [user.first_name, user.last_name].join(' ')
          given_name user.first_name
          family_name user.last_name
        end

        config.add_client do
          name 'Test Client'
          identifier "client-#{OIDCProvider.clients.size + 1}"
          secret SecureRandom.hex(4)
          redirect_uri(2.times.map { 'https://client.example.com/oidc/callback' })
        end
      end
    end

    context 'when using the first redirect_uri' do
      let(:scopes) { ERB::Util.url_encode(%w[openid profile email].join(' ')) }

      def first_redirect_uri
        client.redirect_uri.first
      end

      before do
        login_and_logout_with_warden(user) do
          # Create an authorization code
          get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{first_redirect_uri}&scope=#{scopes}&nonce=#{nonce}"

          authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

          # Create an access_token from the authorization code
          post create_token_url(authorization_code, first_redirect_uri)

          access_token = response.parsed_body['access_token']

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
        expect(response.parsed_body).to include('name' => "#{user[:first_name]} #{user[:last_name]}")
      end

      it "responds with a given_name containing the user's first_name" do
        expect(response.parsed_body).to include('given_name' => user[:first_name])
      end

      it "responds with a family_name containing the user's last_name" do
        expect(response.parsed_body).to include('family_name' => user[:last_name])
      end

      it "responds with a email containing the user's email" do
        expect(response.parsed_body).to include('email' => user[:email])
      end

      it 'responds with a email_verified being true' do
        expect(response.parsed_body).to include('email_verified' => true)
      end
    end

    context 'when using the last redirect_uri' do
      let(:scopes) { ERB::Util.url_encode(%w[openid profile email].join(' ')) }

      def last_redirect_uri
        client.redirect_uri.last
      end

      before do
        login_and_logout_with_warden(user) do
          # Create an authorization code
          get "#{one_test_server_url}/accounts/oauth/authorizations?client_id=#{client.identifier}&response_type=code&redirect_uri=#{last_redirect_uri}&scope=#{scopes}&nonce=#{nonce}"

          authorization_code = response.location[/\?code=([a-z0-9]+)/, 1]

          # Create an access_token from the authorization code
          post create_token_url(authorization_code, last_redirect_uri)

          access_token = response.parsed_body['access_token']

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
        expect(response.parsed_body).to include('name' => "#{user[:first_name]} #{user[:last_name]}")
      end

      it "responds with a given_name containing the user's first_name" do
        expect(response.parsed_body).to include('given_name' => user[:first_name])
      end

      it "responds with a family_name containing the user's last_name" do
        expect(response.parsed_body).to include('family_name' => user[:last_name])
      end

      it "responds with a email containing the user's email" do
        expect(response.parsed_body).to include('email' => user[:email])
      end

      it 'responds with a email_verified being true' do
        expect(response.parsed_body).to include('email_verified' => true)
      end
    end
  end
end
