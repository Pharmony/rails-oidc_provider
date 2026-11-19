# frozen_string_literal: true

require_relative '../rails_oidc_provider/version'

module OIDCProvider
  VERSION = RailsOidcProvider::VERSION unless const_defined?(:VERSION, false)
end
