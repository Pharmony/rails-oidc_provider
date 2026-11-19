# rails-oidc_provider — Agent Guidance

Rails engine gem providing OpenID Connect provider capabilities. Public API is
`OIDCProvider`; `RailsOidcProvider` is a transition alias.

## Non-negotiable

- Never force-push or rewrite published tags/releases.
- Do not mention consuming applications by name in this repository.
- Never expose signing key material or passphrases in logs or commits.
- `spec/dummy/lib/oidc_provider_key.pem` must stay gitignored.
- Do **not** bump `RailsOidcProvider::VERSION` or cut a release tag in the same
  change that lands a fix unless the user explicitly asks to publish. Default
  flow is: land the fix on `master` → wait for CI green → then version + release.

## Layout

- `app/`, `config/`, `db/`, `lib/oidc_provider*` — engine implementation
- `lib/rails_oidc_provider*` — gem identity / version / alias
- `lib/rails-oidc_provider.rb`, `lib/rails/oidc_provider.rb` — Bundler.require
  entrypoints (required; without them hosts get `uninitialized constant OIDCProvider`)
- `spec/requests` — RSpec suite; `spec/dummy` — host app under test
- `spec/gem_structure_spec.rb` — packaging + Bundler load-path guarantees
- `Dockerfile`, `docker-compose.yml` — local and CI test runner

## Verification

```sh
docker compose run --rm test
docker compose run --rm test bundle exec rubocop
```

## Release flow

1. Merge/push the fix or feature to `master` **without** a version bump when
   the user wants CI confirmation first.
2. Wait until GitHub Actions CI is green on that commit.
3. Only then, in a **separate** commit (when asked to publish):
   - Bump `RailsOidcProvider::VERSION` in `lib/rails_oidc_provider/version.rb`
   - Move `[Unreleased]` notes into a new `## [X.Y.Z]` section in `CHANGELOG.md`
     and update the compare links at the bottom
   - Push that commit, then run `bin/release` (tags `v$VERSION` and triggers
     `.github/workflows/release.yml` → RubyGems + GitHub Release)
4. Never re-tag or force-push an already published version.
