# alirokeys.com — Full Dev Plan (front-end-first)

> Status: **awaiting go on Phase 0.** This is the agreed reference plan. Update it as decisions change.

## 1. Concept
A web app to **publish, discover, and securely hand off Aliro reader configurations**. An
**AliroConfig** = `{ name, reader_group_id, reader_public_key, reader_certificate? }` created by a user
account. The app **validates** key material (never generates it), groups configs under **domains** for
public discovery, renders every field in multiple copyable encodings, exports the config as idiomatic
source in many languages, and supports **burn-on-read one-time share links**.

It fills the gap the Aliro spec leaves open: the spec defines the phone↔reader radio protocol but says
nothing about how parties *discover and exchange* each other's public trust material out of band.

Reference spec: `~/Downloads/26-42802-001_Aliro_1.0_specification.pdf` (CSA Aliro 1.0). The backend
roles (Credential Issuer, Access Manager, Reader System Issuer) are out of scope of the spec; this app
is an out-of-band discovery/exchange tool for public trust material.

## 2. Approach: production front-end first, then wire the backend
- **Phase 0 builds the real, production-quality UI** — final HTML, Tailwind styling, and Stimulus
  interactions — backed by **static sample data** (no DB/auth/validation yet). This front-end is
  **kept**, not thrown away.
- We **refine the UI together until happy** (review gate).
- Then later phases **build the backend behind those same views** — auth, models, validation, exports,
  sharing — swapping static data for live data without redoing the UI.

## 3. Stack (matches existing scaffold)
- **Rails 8.0.5**, Ruby 3.2.3, **SQLite**, Puma.
- **Hotwire** (Turbo + Stimulus), **Propshaft**, **importmap**.
- **Tailwind** via `tailwindcss-rails`.
- **Devise** + **`devise-passwordless`** (magic-link) + `:timeoutable` (short sessions).
- Minitest + Capybara; Brakeman.
- Solid Queue (present) for mailer jobs.
- *(No `rubyzip` — exports are per-language source files, not zips.)*

## 4. Authentication & authorization
- **Magic-link only, no passwords** (Devise + devise-passwordless): enter email → receive one-time
  login link.
- **Org-email-only:** free-mail domains rejected before any link is sent. Curated list in
  `config/free_email_domains.yml` + email validator. Rejection copy: *"Please use your organization
  email address."*
- **Short sessions:** Devise `:timeoutable`, `timeout_in` ≈ **30 min**, no "remember me." Lose email
  access → can't re-auth → locked out in minutes (the "fired" model).
- **Authorization:**
  - Authenticated → may create configs (under any domain name — open claiming) and mint one-time shares.
  - **Edit/delete limited to the config's `created_by` user.**
  - No domain-email-match gate; domains are open labels, not owned.
- Public/unauthenticated: domain profiles, sample config pages, language exports for samples,
  one-time-share retrieval (secret-gated).

## 5. Data model (built in Phase 3, behind the Phase 0 UI)
**User** (Devise passwordless): `email` (unique, org-domain only), timeoutable/magic-link fields, no
password.

**Domain:** `name` (unique, lowercased, e.g. `allegion.com`); created lazily on first config; no owner;
`has_many :aliro_configs`.

**AliroConfig:**
- `name` (required), `created_by_id` (User, displayed on the page), `domain_id`.
- `reader_group_id` (16 bytes), `reader_public_key` (65 bytes uncompressed P-256),
  `reader_certificate` (nullable, §13.3 compressed cert).
- `is_sample` (boolean) — **only `is_sample = true` appears on the public domain profile.**

**OneTimeShare:** `token` (URL-safe, unique), `aliro_config_id` (nullable; nulled on consume),
`secret_digest` (bcrypt), `expires_at` (default +24h), `retrieved_at` (tombstone on consume).

## 6. Validation core (pure `OpenSSL` stdlib — highest-value code)
- **reader_public_key:** 65 bytes, `0x04` prefix, **point actually on the P-256 curve** (construct
  `OpenSSL::PKey::EC::Point`; invalid raises).
- **reader_group_id:** decodes to exactly **16 bytes**.
- **reader_certificate (optional):** parse §13.3 compressed-cert TLV, extract `0x85` embedded pubkey,
  verify it's valid P-256 and **matches `reader_public_key`**. *(Read §13.3 closely here; fallback to
  TLV-structure + embedded-key-on-curve validation if full decompress is too deep for v1, noted in
  README.)*
- **Inputs:** every field accepts **hex (±`0x`) or base64**; normalized to raw bytes on save; clear
  inline hints + per-field errors.

## 7. Per-field encodings + per-language exports
**Per-field copy** (each of the 3 fields), via a `BytesPresenter`: raw hex, 0x-hex, base64, C array,
Swift array, Java array.

**Per-language full-config export**, via a template-driven `CodeExporter` — **copyable on the page and
downloadable as a file**:

| Lang   | File      | Shape (group id) |
|--------|-----------|------------------|
| JSON   | `.json`   | `{ "reader_group_id":"17cb…","reader_public_key":"0418…","reader_certificate":null }` (hex + base64 keys) |
| C      | `.c`/`.h` | `static const uint8_t reader_group_id[] = { 0x17, … };` |
| Swift  | `.swift`  | `let readerGroupId: [UInt8] = [0x17, …]` |
| Python | `.py`     | `READER_GROUP_ID = bytes.fromhex("17cb…")` |
| Ruby   | `.rb`     | `READER_GROUP_ID = ["17cb…"].pack("H*")` |
| PHP    | `.php`    | `<?php $reader_group_id = hex2bin("17cb…"); …` |
| JS     | `.js`     | `export const readerGroupId = Uint8Array.from([0x17, …]);` |
| Java   | `.java`   | `static final byte[] READER_GROUP_ID = { (byte)0x17, … };` |

Each file carries a comment header (name, domain, source URL, generated note); cert included only when
present. Renderer is template-based so adding languages is trivial. Same `CodeExporter` powers both the
public export route and the one-time `/native.:lang` API.

## 8. One-time share (burn-on-read)
- Authed user picks a config → "Create share" → returns **link + secret shown once** (secret stored only
  as bcrypt digest).
- Retrieval (UI `GET/POST /s/:token`; API `POST /api/v1/shares/:token/native.:lang`): on correct secret,
  not expired, first use — in **one atomic transaction**: serialize/render the config, **`destroy` the
  AliroConfig row**, set `retrieved_at`, null `aliro_config_id`.
- Config delivered exactly once, then **gone from the DB**. Second visit / wrong secret / expired →
  generic "unavailable." **Rate-limited** (Rails 8 `rate_limit`) on retrieval and magic-link requests.

## 9. Routes (locked)
**Public**
- `GET /` — landing / what-is-this + search.
- `GET /:domain` — public profile; lists `is_sample` configs.
- `GET /:domain/configs/samples/:id` — public config page (only if `is_sample`).
- `GET /:domain/configs/:id.(json|py|rb|php|swift|c|h|js|java)` — language export (public if
  `is_sample`, else authed).
- `GET|POST /s/:token` — one-time retrieval UI.
- `POST /api/v1/shares/:token/native.(json|py|rb|php|swift|c|…)` — one-time retrieval API (renders config
  in requested language, then burns it).

**Authenticated**
- Devise magic-link routes (`/users/sign_in`, link callback).
- `resources :aliro_configs` (new/create/edit/update/destroy, **creator-scoped**), domain entered/selected
  on create.
- `POST /aliro_configs/:id/shares` — mint one-time share.
- "My configs" dashboard.

*(Lang extensions registered as custom MIME types, constrained to the whitelist. `/configs/samples/:id`
vs `/configs/:id.:format` disambiguate by segment shape.)*

## 10. Build phases

### Phase 0 — Production-quality front-end (static data) ⭐ start here
Build the **real, final UI** — kept for production — with static sample data, no auth/DB/validation.
Routes mirror §9 so navigation reflects the real IA.
- Install Tailwind; establish design system (layout, nav, typography, components, flash/empty/error
  states).
- Static sample data from real examples (Kastle, Google `f7yuSmdgTPS2D9EMRF0fDQ==`,
  `17cb8ab0…`/`0418e0ba…`) in view locals/constants.
- Thin render-only controllers for every screen:
  1. `GET /` landing + search.
  2. Sign-in (email entry) → "check your email" (mocked).
  3. `GET /:domain` public profile.
  4. `GET /:domain/configs/samples/:id` — **key screen**: name, creator, 3 fields × per-encoding copy,
     per-language Export row (Copy + Download).
  5. "My configs" dashboard (mocked authed state).
  6. New/edit config form — hex/base64 inputs, format hints, sample validation-error state.
  7. Mint one-time share → "link + secret shown once."
  8. `GET/POST /s/:token` — enter-secret / revealed / already-used states.
- **Production Stimulus controllers** (real, reused later): clipboard copy, encoding+language tab
  switching, secret reveal/toggle, copy-confirmation feedback. Download links stubbed until Phase 4.

**⏸ Review gate — refine UI together until sign-off. No backend work begins until then.**

### Phase 1 — Foundation
Gems (`devise`, `devise-passwordless`, `tailwindcss-rails`); finalize Tailwind/build config; keep Phase 0
layout/components as the canonical UI.

### Phase 2 — Auth
Passwordless magic-link User; `:timeoutable` short sessions; `config/free_email_domains.yml` + email
validator; magic-link mailer + dev preview; wire real auth into the Phase 0 sign-in screens;
authenticated `before_action` scaffolding.

### Phase 3 — Models + validation core
`Domain`, `AliroConfig` (`name`, `created_by`, `is_sample`, key fields), lazy domain creation;
`ReaderKeyValidator` (+ cert validator); hex/base64 normalization; creator-scoped CRUD wired behind the
Phase 0 forms/dashboard.

### Phase 4 — Display + exports (wire to live data)
`BytesPresenter` + `CodeExporter`; connect the Phase 0 copy/export UI to real configs; implement language
export endpoints + downloads.

### Phase 5 — Public registry + API
Real domain profiles, public sample config pages (sample-only gating), public JSON API (jbuilder).

### Phase 6 — One-time share
`OneTimeShare`; mint flow (link + one-time secret reveal); atomic burn-on-read (destroys config); expiry;
bcrypt secret; `rate_limit`; `/native.:lang` API — all behind the Phase 0 share/retrieval screens.

### Phase 7 — Tests, hardening, docs
Minitest: validators (on/off-curve, wrong length, hex vs base64), one-time semantics (single-use,
destroys config, expiry, wrong secret), authz (creator-only edit/delete), free-mail rejection. Capybara
happy path (login → add → publish → share → burn). Brakeman pass. README: setup, prod SMTP for magic
links, cert-validation scope note.

## 11. Assumptions baked in (override any)
1. Create = any authenticated user; **edit/delete = creator only**.
2. Domains are **open labels** (publish samples under any name).
3. Session timeout **30 min**; share expiry default **24h**.
4. Free-mail blocklist applies to **login emails**.
5. Creator's email is **shown** on config pages.
6. Languages shipped: **JSON, C, Swift, Python, Ruby, PHP, JS, Java** (extensible).
7. SQLite for v1; magic-link mail via Solid Queue + SMTP env in prod, preview in dev.

## 12. Reference key formats (from user-provided examples)
- **reader_group_id** = 16 bytes. Examples: `f7yuSmdgTPS2D9EMRF0fDQ==` (base64),
  `17cb8ab0dcd640f3a03cfa2aae7a5775` (hex). In a 32-byte `reader_identifier` it is the leading 16 bytes
  (group_id ‖ group_sub_id per spec §6.2).
- **reader_public_key** = 65-byte uncompressed P-256 point (`0x04` ‖ X32 ‖ Y32, 130 hex chars). Example:
  `0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89`.
  Plays two spec roles depending on config (reader's own `reader_PubK`, or the Reader System Issuer CA
  key) — same byte format, one validator.
- **reader_certificate** (optional) = §13.3 compressed Aliro reader cert (~181 bytes; `0x85` tag carries
  the embedded 65-byte pubkey).
