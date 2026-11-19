# frozen_string_literal: true

# Bundler.require tries Kernel.require(gem.name) first for hyphenated gems.
# See bundler/runtime.rb — without this file the engine never loads in hosts.
require_relative 'rails_oidc_provider'
