# frozen_string_literal: true

# Bundler.require falls back to gem.name.tr('-', '/') when the hyphenated
# require fails. Keep this path so either resolution order loads the engine.
require_relative '../rails_oidc_provider'
