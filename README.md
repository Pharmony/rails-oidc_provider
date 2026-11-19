# rails-oidc_provider

> **This repository is a new gem** (`rails-oidc_provider`), historically derived
> from [brandnewbox/oidc_provider](https://github.com/brandnewbox/oidc_provider).
> It is **not** an official continuation of that project. The maintainers of the
> original gem were unresponsive; this codebase packages the engine under a new
> name with its own release line, tests, and CI.
>
> The public Ruby API remains **`OIDCProvider`** (engine, models, configuration)
> so existing applications can migrate with minimal code changes. Prefer the
> **`RailsOidcProvider`** alias for new code when you want the new gem identity.

A Rails engine that turns a host application into an [OpenID Connect](https://openid.net/connect/)
provider, built on [`openid_connect`](https://github.com/nov/openid_connect).

## Requirements

- Ruby >= 3.1
- Rails >= 7.0
- A host-app authentication stack exposing `authenticate_user!`, `current_user`,
  and `sign_out` (Devise is the usual choice; the dummy app uses a minimal
  session equivalent for tests)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-oidc_provider'
```

Then:

```bash
bundle install
rails generate oidc_provider:install
rails oidc_provider:install:migrations
rails db:migrate
```

The install generator still writes `config/initializers/oidc_provider.rb` and
mounts:

```ruby
mount OIDCProvider::Engine, at: '/accounts/oauth'
get '/.well-known/:id', to: 'oidc_provider/discovery#show'
```

### Migrating from `oidc_provider`

1. Replace `gem 'oidc_provider', ...` with `gem 'rails-oidc_provider'`.
2. Keep `OIDCProvider.configure` and existing mounts/migrations — table names and
   the `OIDCProvider` constant are unchanged.
3. Optionally start using `RailsOidcProvider.configure` (delegates to the same API).

### Private key

ID tokens are signed with an RSA private key at `lib/oidc_provider_key.pem` in the
host app (override with `OIDC_PROVIDER_PRIVATE_KEY_PATH`). Passphrase:
`OIDC_PROVIDER_KEY_PASSPHRASE`.

```bash
rails oidc_provider:generate_key
```

## Configuration

```ruby
OIDCProvider.configure do |config|
  config.issuer = 'https://www.example.com'
  config.account_class = 'User'

  config.add_client do
    name 'Test Client'
    identifier '0001'
    secret 'secret'
    redirect_uri 'https://app.example.com/oidc/callback'
  end

  config.add_scope OIDCProvider::Scopes::Profile do |user|
    name user.full_name
    given_name user.first_name
    family_name user.last_name
  end

  config.add_scope OIDCProvider::Scopes::Email do |user|
    email user.email
    email_verified true
  end
end
```

## Running tests with Docker

The suite runs against a SQLite dummy Rails app inside Docker so you do not need
a local Ruby/Rails toolchain matching CI.

### One Ruby × Rails pair

```bash
# Defaults: Ruby 3.3 × Rails 7.1
bin/test-matrix

# Explicit pair
bin/test-matrix 3.2 7.2
bin/test-matrix --rubocop 3.3 7.1

# Compose equivalent (MATRIX_* avoids clashing with host rbenv RUBY_VERSION)
MATRIX_RUBY=3.2 MATRIX_RAILS=7.2 docker compose build test
MATRIX_RUBY=3.2 MATRIX_RAILS=7.2 docker compose run --rm test

# RuboCop in the test image
docker compose run --rm test bundle exec rubocop
```

### Full local matrix

```bash
bin/test-matrix --all
```

Supported pairs match CI: Ruby 3.1–3.3 × Rails 7.0/7.1/7.2/8.0 (compatible only).

### Without Docker

```bash
RAILS_VERSION=7.1 bundle install
OIDC_PROVIDER_KEY_PASSPHRASE=test-passphrase bundle exec rake app:db:prepare
OIDC_PROVIDER_KEY_PASSPHRASE=test-passphrase bundle exec rspec
bundle exec rubocop
```

## Continuous integration

GitHub Actions (`.github/workflows/ci.yml`) on `master` PRs/pushes:

- **RSpec matrix** — Ruby × Rails pairs (see workflow)
- **RuboCop** — Ruby 3.3 / Rails 7.1
- **Docker smoke** — `bin/test-matrix 3.3 7.1`

## Releasing to RubyGems.org

Publishing is done by CI when you push a version tag (`v*`). Prefer
[Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) (OIDC) over
long-lived API keys.

### One-time setup

1. Create an account on [rubygems.org](https://rubygems.org) (enable MFA).
2. Push the gem once if it does not exist yet (optional first bootstrap):
   ```bash
   gem build rails-oidc_provider.gemspec
   gem push rails-oidc_provider-1.0.0.gem   # prompts for credentials / OTP
   ```
3. On the gem’s RubyGems page → **Trusted Publishing** → add a GitHub provider:
   - **Organization or user:** `pharmony`
   - **Repository:** `rails-oidc_provider`
   - **Workflow filename:** `release.yml`
   - **Environment:** leave blank (unless you set `environment:` in the workflow)

No `RUBYGEMS_API_KEY` secret is required when Trusted Publishing is configured.

### Cut a release

1. Bump `RailsOidcProvider::VERSION` in `lib/rails_oidc_provider/version.rb`.
2. Update `CHANGELOG.md` for that version.
3. Commit and push `master`.
4. Tag and push (triggers `.github/workflows/release.yml`):
   ```bash
   bin/release           # tags v$VERSION, pushes branch + tag
   bin/release --dry-run # show what would run
   ```
   Equivalent manual steps:
   ```bash
   version=$(ruby -e "require_relative 'lib/rails_oidc_provider/version'; puts RailsOidcProvider::VERSION")
   git tag -a "v${version}" -m "Release v${version}"
   git push origin master
   git push origin "v${version}"
   ```
5. Confirm the **Release** workflow is green. It will:
   - publish the gem to https://rubygems.org/gems/rails-oidc_provider
   - create a **GitHub Release** for the tag whose notes are the matching
     section extracted from `CHANGELOG.md` (and attach the built `.gem`)

The workflow fails if the tag (e.g. `v1.0.1`) does not match `VERSION` (`1.0.1`),
or if `CHANGELOG.md` has no `## [1.0.1]` heading (notes fall back to a short
default message).

### Local build only (no push)

```bash
bundle exec rake build    # writes pkg/rails-oidc_provider-*.gem
bundle exec rake install  # install into local gems for smoke testing
```

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).

Original engine copyright Brand New Box / contributors; this package continues
under MIT with additional maintenance copyright for the `rails-oidc_provider`
release line.
