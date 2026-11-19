# frozen_string_literal: true

require_relative 'rails_oidc_provider/version'
require 'oidc_provider'

# Transition alias: prefer `rails-oidc_provider` / RailsOidcProvider while keeping
# the historical OIDCProvider API as the implementation.
module RailsOidcProvider
  class << self
    def method_missing(method_name, ...)
      return super unless OIDCProvider.respond_to?(method_name)

      OIDCProvider.public_send(method_name, ...)
    end

    def respond_to_missing?(method_name, include_private = false)
      OIDCProvider.respond_to?(method_name, include_private) || super
    end

    def const_missing(name)
      OIDCProvider.const_get(name)
    end
  end
end

module OIDCProvider
  VERSION = RailsOidcProvider::VERSION unless const_defined?(:VERSION, false)
end
