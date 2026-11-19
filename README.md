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

# Compose equivalent
RUBY_VERSION=3.2 RAILS_VERSION=7.2 docker compose build test
RUBY_VERSION=3.2 RAILS_VERSION=7.2 docker compose run --rm test
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

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).

Original engine copyright Brand New Box / contributors; this package continues
under MIT with additional maintenance copyright for the `rails-oidc_provider`
release line.
