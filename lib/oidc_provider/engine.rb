# frozen_string_literal: true

require 'rack/oauth2'

module OIDCProvider
  class Engine < ::Rails::Engine
    isolate_namespace OIDCProvider

    config.middleware.use Rack::OAuth2::Server::Rails::Authorize
    config.middleware.use Rack::OAuth2::Server::Resource::Bearer, 'OpenID Connect' do |req|
      AccessToken.valid.find_by(token: req.access_token) ||
        req.invalid_token!
    end

    # Host apps install migrations with:
    #   rails oidc_provider:install:migrations
    # The engine dummy app under spec/dummy receives them via railties engine.rake
    # (do not also append here or migrations load twice).
  end
end
