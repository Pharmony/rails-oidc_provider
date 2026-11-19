# frozen_string_literal: true

module OIDCProvider
  # Inherits from the host app's ApplicationController so methods like
  # authenticate_user!, current_user and sign_out (Devise or custom) work.
  class ApplicationController < ::ApplicationController
    def oidc_current_account
      send(OIDCProvider.current_account_method)
    end

    def current_token
      @current_token ||= request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    end

    def require_authentication
      send(OIDCProvider.current_authentication_method)
    end

    def require_access_token
      raise Rack::OAuth2::Server::Resource::Bearer::Unauthorized unless current_token
    end

    def unauthenticate!
      send(OIDCProvider.current_unauthenticate_method)
    end
  end
end
