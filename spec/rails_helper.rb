# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
ENV['APP_HOST'] ||= 'www.example.com'
ENV['OIDC_PROVIDER_KEY_PASSPHRASE'] ||= 'test-passphrase'

require_relative 'spec_helper'
require_relative 'dummy/config/environment'

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

key_path = OIDCProvider::IdToken.oidc_provider_key_path
unless File.exist?(key_path)
  require 'rake'
  Rails.application.load_tasks
  Rake::Task['oidc_provider:generate_key'].invoke
end

# Dummy owns all test migrations under spec/dummy/db/migrate
migrate_paths = [Rails.root.join('db/migrate').to_s]
ActiveRecord::Migrator.migrations_paths = migrate_paths

begin
  ActiveRecord::MigrationContext.new(migrate_paths).migrate
rescue ArgumentError
  # Rails 7.0 expects (paths, schema_migration)
  ActiveRecord::MigrationContext.new(migrate_paths, ActiveRecord::SchemaMigration).migrate
end

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  # fixture_paths= is Rails 7.1+ / newer rspec-rails; older stacks use fixture_path=
  if config.respond_to?(:fixture_paths=)
    config.fixture_paths = []
  elsif config.respond_to?(:fixture_path=)
    config.fixture_path = nil
  end

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :controller

  config.before(:each, type: :request) do
    host! ENV.fetch('APP_HOST', 'www.example.com')
    https!
  end

  config.before(:each, type: :controller) do
    request.env['HTTPS'] = 'on' if defined?(request) && request
  end
end
