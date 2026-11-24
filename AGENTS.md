# AGENTS.md

## What this is

Zero-build static PWA marketplace (Jalsa event). No package.json, no npm, no bundler, no tests, no lint, no CI. Do not introduce a toolchain unless asked.

- `index.html` — the entire app: HTML + CSS + JS in one file (~3900 lines). Sections are numbered in comments (§0 CONFIG … §21 BOOT). Read the section index at line ~725 before searching.
- `sw.js` — service worker (network-first, cache fallback)
- `manifest.webmanifest`, `icons/`, `jalsa logo.png` — PWA assets
- `supabase_schema.sql` — full schema, RLS policies, security-definer functions
- `SUPABASE_SETUP.md`, `PROJECT_STRUCTURE.md` — docs (see "Docs lag code" below)

## Commands

Serve over HTTP (ES modules fail on `file://`):

```bash
python -m http.server 4173     # port 4173 is the convention — Supabase redirect allowlist references http://localhost:4173
# or: npx serve . -p 4173
```

There is no build, lint, typecheck, or test command. Verification = load the page in a browser and exercise the flow manually.

## Docs lag code — trust `index.html`

`SUPABASE_SETUP.md` and `PROJECT_STRUCTURE.md` describe email OTP/magic-link auth and name+phone RPC login (`jalsa_lookup_login`). The working copy of `index.html` has diverged:

- Signup uses `signInAnonymously()` + direct `profiles`/`vendors` upsert (no email field in the signup forms anymore). Profile-save errors now throw instead of being swallowed, so a broken account can't be created silently.
- **Logout is soft**: anonymous accounts cannot re-authenticate after `signOut()`, so `logout()` only sets `localStorage['jalsa.signed_out']` and clears in-memory state — it never calls `signOut()`. `restoreSession()` returns false while that flag is set, and `loginByNameAndPhone` re-attaches the device's existing session by matching the caller's own `profiles` row (RLS-safe) on phone (digits, last-10 tolerant) + first name. Consequence: **one account per browser**, and a "logged out" session stays technically valid.
- **The Email auth provider is disabled** in the Supabase project — `signInWithPassword`/`signInWithOtp` fail with `email_provider_disabled`. Do not reintroduce them.

`index.html` also currently has **uncommitted changes** implementing this. Before editing auth, read the actual functions (`customerSignup`, `vendorSignup`, `loginByNameAndPhone`, `restoreSession`, `logout` around lines 1470–1645) and check `git diff index.html`.

## Configuration

Everything is in the `CONFIG` object at `index.html:733` (Supabase URL/anon key, WhatsApp numbers, `PAGE_SIZE`, `ADMIN_PATH`). No `.env`. `IS_CONFIGURED` (line 742) gates a localStorage **demo mode** fallback when Supabase values are empty — auth/cart/saved flows all branch on `!supabase`. Never add the `service_role` key.

`ADMIN_PATH` (`index.html:740`, value `Adminfash`) is the secret username for the admin form (`fd.get('username') !== CONFIG.ADMIN_PATH` at line 3033). The `#/admin` hash route alone is not protection. Admin sign-in has **no email**: the form signs in anonymously, then calls the `jalsa_claim_admin(p_secret)` RPC (security definer, bcrypt check against the `admin_secrets` table, grants `admin_users` for `auth.uid()`). That function lives only in `supabase_schema.sql` — if the SQL hasn't been run, the RPC call fails.

## Gotchas

- **Supabase JS is loaded at runtime** via dynamic `import()` from jsDelivr (`index.html:941`). App breaks without network even though the shell is cached.
- **Service worker**: `CACHE_NAME` is `jalsa-market-v2` (bump it on any shell change or clients keep stale `index.html`). It caches same-origin GETs only (never Supabase API/auth/storage) and pre-caches assets individually so a missing file can't fail install.
- **Schema changes**: `supabase_schema.sql` is run manually in the Supabase SQL Editor — there are no migrations. It contains security-definer functions (`jalsa_authenticate_login` sets a deterministic password per user) that may or may not still be called; grep `index.html` before assuming they're used.
- **File has a UTF-8 BOM** and git converts LF→CRLF on checkout; don't "fix" line endings or strip the BOM as drive-by changes.
- `PROJECT_STRUCTURE.md` says "Generated automatically — do not edit by hand."

## Manual test checklist

No automated tests. After auth or RLS changes, verify: signup creates profile (+ pending vendor for vendors), logout returns to the login screen and login restores the same profile via name+phone, wrong phone/name is rejected, reload while signed out shows guest mode (header "Sign In" returns to login), vendor dashboard still writes after logout→login, RLS blocks cross-user edits, images land in the right bucket (`vendor-logos`, `store-covers`, `product-images`).
