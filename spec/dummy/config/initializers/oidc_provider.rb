# frozen_string_literal: true

OIDCProvider.configure do |config|
  config.issuer = "https://#{ENV.fetch('APP_HOST', 'www.example.com')}"
  config.account_class = 'User'
  config.account_identifier = :id
end
