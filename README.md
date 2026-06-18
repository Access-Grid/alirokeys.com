# Aliro Keys — by AccessGrid.com

A directory to **publish, discover, and securely hand off Aliro reader configurations**
(CSA Aliro 1.0 public trust material). It validates key material (never generates it),
groups configs under email-verified domains, renders/exports them in many encodings and
languages, and supports burn-on-read one-time share links.

An *AliroConfig* = `{ name, reader_group_id, reader_public_key, reader_certificate? }`.

See **[PLAN.md](PLAN.md)** for the full design and phase history.

## Stack

Rails 8 · Ruby 3.2 · SQLite · Hotwire (Turbo/Stimulus) · Propshaft + import maps ·
Tailwind v4 (`tailwindcss-rails`) · Devise + `devise-passwordless` · Solid Queue/Cache/Cable.
Tests: Minitest + Capybara. Security scan: Brakeman.

## Getting started

```bash
bundle install
bin/rails db:prepare   # create + migrate
bin/rails db:seed      # sample domains/configs (idempotent)
bin/dev                # Rails + Tailwind watch  ->  http://localhost:3000
```

### Authentication (passwordless)

Login is **magic-link only** and restricted to **organization emails** (free-mail
providers are rejected — see `config/free_email_domains.yml`). Sessions are short-lived
(~30 min). In **development**, outbound email opens automatically in the browser via
`letter_opener` — click the link inside it to sign in. In **production**, configure SMTP
and `config.action_mailer.default_url_options` so magic links resolve to your host.

Any authenticated user can publish configs under any domain and mint share links;
**only a config's creator can edit or delete it.** Creator emails are never displayed
or returned anywhere.

## What it does

- **Validation core** (`KeyMaterial`): accepts hex or base64; checks a 16-byte reader
  group id, a 65-byte uncompressed P-256 public key that actually lies on the curve, and
  (if given) a reader certificate that embeds that public key. Stored normalized as hex.
- **Public registry**: `GET /:domain` lists a domain's `is_sample` configs.
- **Per-config page**: every field copyable in hex / 0x / base64 / C / Swift / Java, plus
  full-config source export in JSON, C, Swift, Python, Ruby, PHP, JS, Java.
- **JSON API**: `GET /:domain/aliro.json` and `GET /api/v1/domains/:name`.
- **One-time shares**: mint a burn-on-read link (`/s/:token`) gated by a secret; on
  retrieval the config is revealed once and **destroyed**. API equivalent:
  `POST /api/v1/shares/:token/native.:lang` (returns the config as source, then burns it).

## Tests

```bash
bin/rails test        # full suite
bin/brakeman          # security scan
```

## Notes / scope

- **Certificate validation** is a pragmatic v1: the cert must be a SEQUENCE that embeds
  the reader public key (the security-relevant binding). Full §13.3 ASN.1/compression
  handling is a later enhancement.
- Key-material input is treated as hex when it's all hex digits and even length, otherwise
  base64 — adequate for a paste tool; ambiguous all-hex base64 strings are read as hex.
- SQLite is fine for this workload; the one-time-share single-use guard is an atomic
  conditional UPDATE (race-safe).
