# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-03-26

First release of **`rails-oidc_provider`**, a maintained OpenID Connect provider
engine for Rails. Historically derived from
[brandnewbox/oidc_provider](https://github.com/brandnewbox/oidc_provider) and the
accumulated community patches previously published on zedtux forks. This is a
**new gem**, not an official continuation of the original project.

The runtime Ruby API remains `OIDCProvider` for drop-in compatibility. A
`RailsOidcProvider` module aliases configuration helpers for the new gem name.

### Added

- Gem name `rails-oidc_provider` at version `1.0.0`.
- `RailsOidcProvider` transition alias delegating to `OIDCProvider`.
- RSpec request suite ported from a consuming application (authorization,
  tokens, claims, clients, discovery, userinfo, JWKS).
- Docker image and `docker compose` workflow for running the test suite locally.
- GitHub Actions CI with Ruby × Rails RSpec matrix, RuboCop, Docker smoke; local bin/test-matrix.
- RuboCop (`rubocop`, `rubocop-rails`, `rubocop-rspec`) for local and CI linting.
- This changelog.

### Fixed (inherited from prior patch line)

- JWKS endpoint returns an RFC 7517 §5 JWK Set object (`{"keys":[...]}`) instead
  of a bare array of JWKs.
- Unsupported OAuth grant types respond with `unsupported_grant_type` (HTTP 400)
  instead of an unhandled 500.
- Authorization redirects to external client hosts work on Rails 7+
  (`allow_other_host: true`).
- `Authorization` claims/scopes serialization works on Rails 7.1+ and older
  Rails (`coder:` keyword when required).
- Configurable private key path via `OIDC_PROVIDER_PRIVATE_KEY_PATH`.
- OpenID `claims` request parameter support on the authorization endpoint.
- Multiple `redirect_uri` values per client.

### Changed

- Single `master` branch replaces the former cumulative `master+patch-*` model.
- Development dependency stack centered on RSpec + SQLite dummy app (Minitest
  engine smoke tests removed).
- Runtime dependency floor raised to Rails `>= 7.0` and Ruby `>= 3.1`.

[Unreleased]: https://github.com/zedtux/rails-oidc_provider/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/zedtux/rails-oidc_provider/releases/tag/v1.0.0
