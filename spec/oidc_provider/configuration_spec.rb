# frozen_string_literal: true

require 'rails_helper'

# Global mattr_accessors snapshotted around each example so request specs keep
# dummy initializer defaults when the suite is run as a whole.
module OIDCProviderConfigurationSpec
  ACCESSORS = %i[
    issuer
    supported_scopes
    clients
    account_class
    current_account_method
    current_authentication_method
    current_unauthenticate_method
    account_identifier
    after_sign_out_path
  ].freeze
end

RSpec.describe OIDCProvider do
  around do |example|
    snapshot = OIDCProviderConfigurationSpec::ACCESSORS.index_with do |name|
      described_class.public_send(name)
    end
    snapshot[:supported_scopes] = snapshot[:supported_scopes]&.dup
    snapshot[:clients] = snapshot[:clients]&.dup
    example.run
  ensure
    OIDCProviderConfigurationSpec::ACCESSORS.each do |name|
      described_class.public_send("#{name}=", snapshot[name])
    end
  end

  describe 'defaults' do
    it 'defaults account integration to Devise-style User helpers' do
      expect(described_class).to have_attributes(
        account_class: 'User',
        current_account_method: :current_user,
        current_authentication_method: :authenticate_user!,
        current_unauthenticate_method: :sign_out,
        account_identifier: :id
      )
    end

    it 'exposes standard scope name constants' do
      expect(described_class::Scopes::OpenID).to eq('openid')
      expect(described_class::Scopes::Profile).to eq('profile')
      expect(described_class::Scopes::Email).to eq('email')
      expect(described_class::Scopes::Address).to eq('address')
    end
  end

  describe '.configure' do
    it 'yields the OIDCProvider module for block configuration' do
      yielded = nil
      described_class.configure { |config| yielded = config }
      expect(yielded).to eq(described_class)
    end

    it 'resets clients and seeds the openid scope on each call' do
      described_class.configure do |config|
        config.add_client do
          name 'Stale'
          identifier 'stale'
          secret 's'
          redirect_uri 'https://stale.example/cb'
        end
        config.add_scope 'custom' do
          foo 'bar'
        end
      end

      described_class.configure do |config|
        config.issuer = 'https://provider.example'
      end

      expect(described_class.clients).to eq([])
      expect(described_class.supported_scopes.map(&:name)).to eq([described_class::Scopes::OpenID])
      expect(described_class.issuer).to eq('https://provider.example')
    end

    it 'assigns host-facing account and session settings' do
      described_class.configure do |config|
        config.issuer = 'https://idp.example'
        config.account_class = 'Administrator'
        config.account_identifier = :uuid
        config.current_account_method = :current_admin
        config.current_authentication_method = :authenticate_admin!
        config.current_unauthenticate_method = :sign_out_admin
        config.after_sign_out_path = '/admin/login'
      end

      expect(described_class).to have_attributes(
        issuer: 'https://idp.example',
        account_class: 'Administrator',
        account_identifier: :uuid,
        current_account_method: :current_admin,
        current_authentication_method: :authenticate_admin!,
        current_unauthenticate_method: :sign_out_admin,
        after_sign_out_path: '/admin/login'
      )
    end
  end

  describe '.add_client' do
    it 'registers a fully attributed client' do
      described_class.configure do |config|
        config.add_client do
          name 'App'
          identifier 'app-1'
          secret 'sekrit'
          redirect_uri 'https://app.example/oidc/callback'
        end
      end

      expect(described_class.clients.first).to have_attributes(
        name: 'App',
        identifier: 'app-1',
        secret: 'sekrit',
        redirect_uri: 'https://app.example/oidc/callback'
      )
    end

    it 'keeps a single String redirect_uri as a String' do
      described_class.configure do |config|
        config.add_client do
          identifier 'string-uri'
          secret 's'
          redirect_uri 'https://client.example/cb'
        end
      end

      expect(described_class.clients.first.redirect_uri).to eq('https://client.example/cb')
    end

    it 'collapses a one-element Array redirect_uri to a String' do
      described_class.configure do |config|
        config.add_client do
          identifier 'one-uri'
          secret 's'
          redirect_uri ['https://client.example/cb']
        end
      end

      expect(described_class.clients.first.redirect_uri).to eq('https://client.example/cb')
    end

    it 'keeps multiple redirect_uri values as an Array' do
      uris = %w[https://a.example/cb https://b.example/cb]
      described_class.configure do |config|
        config.add_client do
          identifier 'multi-uri'
          secret 's'
          redirect_uri uris
        end
      end

      expect(described_class.clients.first.redirect_uri).to eq(uris)
    end

    it 'requires a block' do
      expect { described_class.add_client }.to raise_error(LocalJumpError)
    end
  end

  describe '.add_scope' do
    before do
      described_class.configure do |config|
        config.add_scope described_class::Scopes::Profile do |account|
          name account.full_name
          given_name account.first_name
          family_name account.last_name
        end

        config.add_scope described_class::Scopes::Email do |account|
          email account.email
          email_verified true
        end
      end
    end

    it 'appends scopes after the seeded openid scope' do
      expect(described_class.supported_scopes.map(&:name)).to eq(
        [
          described_class::Scopes::OpenID,
          described_class::Scopes::Profile,
          described_class::Scopes::Email
        ]
      )
    end

    it 'collects claim names from the scope block' do
      profile = described_class.find_scope(described_class::Scopes::Profile)
      email = described_class.find_scope(described_class::Scopes::Email)

      expect(profile.claims).to include(:name, :given_name, :family_name)
      expect(email.claims).to include(:email, :email_verified)
    end
  end

  describe 'scope lookups' do
    before do
      described_class.configure do |config|
        config.add_scope 'profile' do
          name 'n'
          nickname 'n'
        end
        config.add_scope 'email' do
          email 'e'
          nickname 'also'
        end
      end
    end

    it 'finds a scope by name' do
      expect(described_class.find_scope('profile').name).to eq('profile')
      expect(described_class.find_scope('missing')).to be_nil
    end

    it 'finds all scopes that declare a claim' do
      scopes = described_class.find_all_scopes_with_claim(:nickname)
      expect(scopes.map(&:name)).to contain_exactly('profile', 'email')
    end

    it 'lists supported claims across scopes' do
      expect(described_class.supported_claims).to include(
        :iss, :sub, :aud, :nonce, :exp, :iat,
        :name, :nickname, :email
      )
    end
  end

  describe 'ClientStore' do
    before do
      described_class.configure do |config|
        config.add_client do
          name 'A'
          identifier 'id-a'
          secret 'secret-a'
          redirect_uri 'https://a.example/cb'
        end
        config.add_client do
          name 'B'
          identifier 'id-b'
          secret 'secret-b'
          redirect_uri 'https://b.example/cb'
        end
      end
    end

    it 'finds a client by attribute hash' do
      store = described_class::ClientStore.new
      expect(store.find_by(identifier: 'id-b', secret: 'secret-b').name).to eq('B')
      expect(store.find_by(identifier: 'id-b', secret: 'wrong')).to be_nil
      expect(store.find_by(identifier: 'missing')).to be_nil
    end
  end

  describe 'RailsOidcProvider alias' do
    it 'delegates configure and readers to OIDCProvider' do
      RailsOidcProvider.configure do |config|
        config.issuer = 'https://alias.example'
        config.add_client do
          identifier 'via-alias'
          secret 's'
          redirect_uri 'https://alias.example/cb'
        end
      end

      expect(RailsOidcProvider.issuer).to eq('https://alias.example')
      expect(RailsOidcProvider.clients.map(&:identifier)).to eq(['via-alias'])
      expect(RailsOidcProvider).to respond_to(:configure, :add_scope)
    end

    it 'resolves OIDCProvider constants through const_missing' do
      expect(RailsOidcProvider::Client).to eq(described_class::Client)
      expect(RailsOidcProvider.const_get(:Scopes)::OpenID).to eq('openid')
    end
  end

  describe 'install generator initializer shape' do
    subject(:template) do
      File.read(
        File.expand_path(
          '../../lib/generators/oidc_provider/templates/initializer.rb',
          __dir__
        )
      )
    end

    it 'documents OIDCProvider.configure with issuer, clients, and scopes' do
      expect(template).to include(
        'OIDCProvider.configure do |config|',
        'config.issuer',
        'config.add_client',
        'config.add_scope OIDCProvider::Scopes::Profile',
        'config.add_scope OIDCProvider::Scopes::Email',
        "redirect_uri '"
      )
    end
  end
end
