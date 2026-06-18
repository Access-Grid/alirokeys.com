# alirokeys.com

Web app to **publish, discover, and securely hand off Aliro reader configurations** (CSA Aliro 1.0
public trust material). Validates key material (never generates it), groups configs under email-verified
domains, renders/exports them in many encodings and languages, and supports burn-on-read one-time share
links.

## The plan
The full, agreed development plan lives in **[PLAN.md](PLAN.md)** — read it first. It is the source of
truth for scope, data model, routes, validation rules, and build phases. Keep it updated as decisions
change.

## Approach (important)
**Front-end first.** Phase 0 builds the real, production-quality UI (HTML + Tailwind + Stimulus) backed by
static sample data — no auth/DB/validation yet. That front-end is kept; later phases wire the backend
behind the same views. Do not start backend work until the Phase 0 UI is signed off.

## Stack
Rails 8.0.5, Ruby 3.2.3, SQLite, Hotwire (Turbo/Stimulus), Propshaft, importmap, Tailwind
(`tailwindcss-rails`), Devise + `devise-passwordless` (magic-link, short sessions), Solid Queue. Tests:
Minitest + Capybara; Brakeman for security.

## Key facts
- AliroConfig = `{ name, reader_group_id (16 bytes), reader_public_key (65-byte uncompressed P-256),
  reader_certificate? (§13.3 compressed) }`, created by a user, grouped under a domain, `is_sample`
  controls public listing.
- Auth: org-email-only magic-link login, ~30 min sessions. Anyone authenticated can create configs/shares
  under any domain; edit/delete is creator-only.
- One-time shares are burn-on-read: consuming a share destroys the underlying AliroConfig in one atomic
  transaction.
- Reference spec PDF: `~/Downloads/26-42802-001_Aliro_1.0_specification.pdf`.
