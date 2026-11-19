# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)
require 'rails_oidc_provider'

module Dummy
  class Application < Rails::Application
    # Match the major.minor under test (RAILS_VERSION matrix).
    defaults = [Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join('.').to_f
    config.load_defaults defaults
    config.eager_load = false
    config.api_only = false
    config.secret_key_base = 'x' * 128
  end
end
