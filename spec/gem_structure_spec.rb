# frozen_string_literal: true

require 'open3'
require 'rubygems/package'
require 'tmpdir'

# Shared paths for packaging / Bundler-require guarantees (outside examples to
# avoid Lint/ConstantDefinitionInBlock and RSpec/LeakyConstantDeclaration).
module GemStructureSpec
  ROOT = File.expand_path('..', __dir__)
  GEM_NAME = 'rails-oidc_provider'
  # Bundler::Runtime#require tries gem.name, then gem.name.tr('-', '/').
  BUNDLER_REQUIRE_PATHS = [
    GEM_NAME,
    GEM_NAME.tr('-', '/')
  ].freeze
end

# structure/packaging contract, not a single class under test
# rubocop:disable-next RSpec/DescribeClass
RSpec.describe 'gem structure and load paths' do
  def lib_file_for_require(require_path)
    File.join('lib', "#{require_path}.rb")
  end

  describe 'source tree entrypoints' do
    GemStructureSpec::BUNDLER_REQUIRE_PATHS.each do |require_path|
      it "provides #{require_path.inspect} for Bundler.require" do
        path = File.join(GemStructureSpec::ROOT, lib_file_for_require(require_path))
        expect(File).to exist(path),
                        "expected #{path} so Bundler can load #{GemStructureSpec::GEM_NAME.inspect}"
      end
    end

    it 'exposes the public API file and gem identity file' do
      expect(File).to exist(File.join(GemStructureSpec::ROOT, 'lib/oidc_provider.rb'))
      expect(File).to exist(File.join(GemStructureSpec::ROOT, 'lib/rails_oidc_provider.rb'))
    end
  end

  describe 'gemspec packaging' do
    let(:specification) do
      Dir.chdir(GemStructureSpec::ROOT) do
        Gem::Specification.load(File.join(GemStructureSpec::ROOT, 'rails-oidc_provider.gemspec'))
      end
    end

    it 'includes Bundler default require files in the packaged file list' do
      packaged = specification.files

      GemStructureSpec::BUNDLER_REQUIRE_PATHS.each do |require_path|
        relative = lib_file_for_require(require_path)
        expect(packaged).to include(relative),
                            "#{relative} must be in the gem or hosts never load OIDCProvider"
      end

      expect(packaged).to include('lib/oidc_provider.rb')
      expect(packaged).to include('lib/rails_oidc_provider.rb')
      expect(packaged).to include('lib/oidc_provider/engine.rb')
    end

    it 'declares lib as the require path' do
      expect(specification.require_paths).to eq(['lib'])
    end

    it 'builds a .gem that still contains Bundler entrypoints' do
      Dir.mktmpdir('rails-oidc_provider-gem-build') do |dir|
        gem_path = File.join(dir, 'built.gem')
        Dir.chdir(GemStructureSpec::ROOT) do
          stdout, stderr, status = Open3.capture3(
            'gem', 'build', 'rails-oidc_provider.gemspec', '--output', gem_path
          )
          expect(status).to be_success, "gem build failed:\n#{stdout}\n#{stderr}"
        end

        packaged_files = Gem::Package.new(gem_path).spec.files

        GemStructureSpec::BUNDLER_REQUIRE_PATHS.each do |require_path|
          expect(packaged_files).to include(lib_file_for_require(require_path))
        end
      end
    end
  end

  describe 'host-style loading' do
    # Mirrors a host app that only lists the gem and calls Bundler.require:
    # without the hyphen/slash entrypoints, OIDCProvider stays undefined and
    # config/initializers/oidc_provider.rb raises NameError at boot.
    def load_via_require_path(require_path)
      # Host apps require Rails (railties) before Bundler.require loads the gem.
      script = <<~RUBY
        gem_root = #{GemStructureSpec::ROOT.inspect}
        $LOAD_PATH.unshift(File.join(gem_root, 'lib'))
        require 'bundler/setup'
        require 'rails'
        require #{require_path.inspect}
        abort('OIDCProvider missing') unless defined?(OIDCProvider)
        abort('OIDCProvider::Engine missing') unless defined?(OIDCProvider::Engine)
        abort('RailsOidcProvider missing') unless defined?(RailsOidcProvider)
        print [OIDCProvider.name, RailsOidcProvider.name, OIDCProvider::Engine.name].join(',')
      RUBY

      Open3.capture3(
        { 'BUNDLE_GEMFILE' => File.join(GemStructureSpec::ROOT, 'Gemfile') },
        'ruby', '-e', script
      )
    end

    GemStructureSpec::BUNDLER_REQUIRE_PATHS.each do |require_path|
      it "defines OIDCProvider after requiring #{require_path.inspect}" do
        stdout, stderr, status = load_via_require_path(require_path)
        expect(status).to be_success, "require #{require_path.inspect} failed:\n#{stderr}\n#{stdout}"
        expect(stdout).to eq('OIDCProvider,RailsOidcProvider,OIDCProvider::Engine')
      end
    end

    it 'defines OIDCProvider after requiring rails_oidc_provider (explicit underscore path)' do
      stdout, stderr, status = load_via_require_path('rails_oidc_provider')
      expect(status).to be_success, "require rails_oidc_provider failed:\n#{stderr}\n#{stdout}"
      expect(stdout).to include('OIDCProvider')
    end

    it 'defines OIDCProvider after requiring oidc_provider (public API path)' do
      stdout, stderr, status = load_via_require_path('oidc_provider')
      expect(status).to be_success, "require oidc_provider failed:\n#{stderr}\n#{stdout}"
      expect(stdout).to include('OIDCProvider')
    end
  end

  describe 'dummy host boot' do
    it 'has OIDCProvider available the way a host initializer uses it' do
      require 'rails_helper'

      expect(defined?(OIDCProvider)).to eq('constant')
      expect(OIDCProvider).to respond_to(:configure)
      expect(OIDCProvider::Engine).to be < Rails::Engine

      previous_issuer = OIDCProvider.issuer
      previous_clients = OIDCProvider.clients.dup
      previous_scopes = OIDCProvider.supported_scopes.dup
      configured = false

      # Same shape as config/initializers/oidc_provider.rb in host apps.
      expect do
        OIDCProvider.configure do |config|
          config.issuer = 'https://structure-spec.example'
        end
        configured = true
      end.not_to raise_error

      expect(OIDCProvider.issuer).to eq('https://structure-spec.example')
    ensure
      if configured
        OIDCProvider.issuer = previous_issuer
        OIDCProvider.clients = previous_clients
        OIDCProvider.supported_scopes = previous_scopes
      end
    end
  end
end
