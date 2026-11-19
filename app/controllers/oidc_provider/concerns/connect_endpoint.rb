# frozen_string_literal: true

module OIDCProvider
  module Concerns
    module ConnectEndpoint
      extend ActiveSupport::Concern

      included do
        helper_method :oauth_request
        rescue_from Rack::OAuth2::Server::Authorize::BadRequest, with: :handle_oauth_error!
      end

      def oauth_request
        request.env[Rack::OAuth2::Server::Rails::REQUEST]
      end

      def oauth_response
        request.env[Rack::OAuth2::Server::Rails::RESPONSE]
      end

      def oauth_error
        request.env[Rack::OAuth2::Server::Rails::ERROR]
      end

      def handle_oauth_error!(error)
        raise error if error.redirect?

        # NOTE: rack middleware should handle this error.

        render plain: error.message, status: error.status
      end

      def require_oauth_request
        raise oauth_error if oauth_error
        return if oauth_request && oauth_response

        raise 'should\'t happen'
      end
    end
  end
end
