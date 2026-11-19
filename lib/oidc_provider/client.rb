# frozen_string_literal: true

module OIDCProvider
  class Client
    attr_accessor :identifier, :secret, :name
    attr_reader :redirect_uri

    def initialize(options = {})
      @identifier = options[:identifier]
      @secret = options[:secret]
      self.redirect_uri = options[:redirect_uri]
      @name = options[:name]
    end

    # Hosts may pass a String (generator/README) or an Array of URIs.
    # rack-oauth2 treats a single registered URI as a String (request may omit
    # redirect_uri) and multiple URIs as an Array (request must send one).
    def redirect_uri=(value)
      values = Array(value).flatten.compact
      @redirect_uri = values.size <= 1 ? values.first : values
    end
  end
end

require 'oidc_provider/client/builder'
