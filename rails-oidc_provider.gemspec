# frozen_string_literal: true

require_relative 'lib/rails_oidc_provider/version'

Gem::Specification.new do |spec|
  spec.name = 'rails-oidc_provider'
  spec.version = RailsOidcProvider::VERSION
  spec.authors = ['Guillaume Hain']
  spec.email = ['zedtux@zedroot.org']

  spec.summary = 'Rails engine that turns an application into an OpenID Connect provider.'
  spec.description = <<~DESC
    A maintained Rails engine for OpenID Connect authorization, historically
    derived from brandnewbox/oidc_provider. The public Ruby API remains
    OIDCProvider, with a RailsOidcProvider alias for the new gem identity.
  DESC
  spec.homepage = 'https://github.com/zedtux/rails-oidc_provider'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md', 'CHANGELOG.md']
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'openid_connect', '~> 2.2.0'
  spec.add_dependency 'rails', '>= 7.0'

  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'sqlite3', '>= 1.4'
end
