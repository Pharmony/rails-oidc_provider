# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Matrix: RAILS_VERSION=7.0|7.1|7.2|8.0 (default 7.1)
rails_version = ENV.fetch('RAILS_VERSION', '7.1')
gem 'rails', "~> #{rails_version}.0"

gem 'puma'
gem 'rspec-rails', '~> 6.0'
gem 'rubocop', '~> 1.65'
gem 'rubocop-rails', '~> 2.25'
gem 'rubocop-rspec', '~> 3.0'

# ActiveRecord 7.0/7.1 require sqlite3 ~> 1.4; 7.2+/8.x need sqlite3 >= 2.1.
if Gem::Version.new(rails_version) >= Gem::Version.new('7.2')
  gem 'sqlite3', '>= 2.1'
else
  gem 'sqlite3', '~> 1.4'
end

# json >= 2.8 dropped quirks_mode, which Rails 7.0/7.1 still pass through.
gem 'json', '~> 2.7.0'
