# rails-oidc_provider — Agent Guidance

Rails engine gem providing OpenID Connect provider capabilities. Public API is
`OIDCProvider`; `RailsOidcProvider` is a transition alias.

## Non-negotiable

- Never force-push or rewrite published tags/releases.
- Do not mention consuming applications by name in this repository.
- Never expose signing key material or passphrases in logs or commits.
- `spec/dummy/lib/oidc_provider_key.pem` must stay gitignored.

## Layout

- `app/`, `config/`, `db/`, `lib/oidc_provider*` — engine implementation
- `lib/rails_oidc_provider*` — gem identity / version / alias
- `spec/requests` — RSpec suite; `spec/dummy` — host app under test
- `Dockerfile`, `docker-compose.yml` — local and CI test runner

## Verification

```sh
docker compose run --rm test
docker compose run --rm test bundle exec rubocop
```
