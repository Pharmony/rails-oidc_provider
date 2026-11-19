# frozen_string_literal: true

module OIDCProvider
  class DiscoveryController < ApplicationController
    def show
      case params[:id]
      when 'webfinger'
        webfinger_discovery
      when 'openid-configuration'
        openid_configuration
      else
        render plain: 'Not found', status: :not_found
      end
    end

    private

    def webfinger_discovery
      jrd = {
        links: [{
          rel: OpenIDConnect::Discovery::Provider::Issuer::REL_VALUE,
          href: OIDCProvider.issuer
        }]
      }
      jrd[:subject] = params[:resource] if params[:resource].present?
      render json: jrd, content_type: 'application/jrd+json'
    end

    def openid_configuration
      config = OpenIDConnect::Discovery::Provider::Config::Response.new(
        authorization_endpoint: absolute_engine_url(:authorizations_url),
        claims_parameter_supported: true,
        claims_supported: OIDCProvider.supported_claims.map(&:to_s),
        end_session_endpoint: absolute_engine_url(:end_session_url),
        grant_types_supported: [:authorization_code],
        id_token_signing_alg_values_supported: [:RS256],
        issuer: OIDCProvider.issuer,
        jwks_uri: absolute_engine_url(:jwks_url),
        response_types_supported: [:code],
        scopes_supported: OIDCProvider.supported_scopes.map(&:name),
        subject_types_supported: [:public],
        token_endpoint: absolute_engine_url(:tokens_url),
        token_endpoint_auth_methods_supported: %w[client_secret_basic client_secret_post],
        userinfo_endpoint: absolute_engine_url(:user_info_url)
      )
      render json: config
    end

    # issuer may be a full origin (https://host); Rails url helpers want host + protocol.
    def absolute_engine_url(helper_name)
      uri = URI.parse(OIDCProvider.issuer.to_s)
      opts = {}
      if uri.host
        opts[:host] = uri.host
        opts[:protocol] = uri.scheme if uri.scheme
        opts[:port] = uri.port if uri.port && ![80, 443].include?(uri.port)
      else
        opts[:host] = OIDCProvider.issuer
      end
      public_send(helper_name, **opts)
    end
  end
end
