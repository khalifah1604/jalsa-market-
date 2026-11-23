# Jalsa Market — Project Structure

> **Discover. Connect. Shop at Jalsa.**  
> A year-round PWA marketplace for Jalsa vendors and customers.

---

## 1. Project Overview

**Jalsa Market** is a mobile-first **Progressive Web App (PWA)** that serves as the official marketplace platform for Jalsa — an annual community event. It connects vendors (sellers) with customers, enabling product discovery, preorders, cart management, WhatsApp-based enquiries, and vendor storefronts, all in a single installable web app.

### Core Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Vanilla HTML5, CSS3 (custom design system), Vanilla JavaScript (ES2022 modules) |
| **Backend / Database** | [Supabase](https://supabase.com) (PostgreSQL + Auth + Storage + RLS policies) |
| **Authentication** | Supabase Auth — Email OTP / Magic Links |
| **Storage** | Supabase Storage (3 public buckets: `vendor-logos`, `store-covers`, `product-images`) |
| **PWA** | Web App Manifest + Service Worker (offline-first, cache-then-network strategy) |
| **Fonts** | Google Fonts — *Instrument Serif* (display) + *Inter* (body) |
| **Icons** | Inline SVG icon set (hand-crafted, no external icon library) |
| **Currency** | Nigerian Naira (₦ / NGN) |
| **Communication** | WhatsApp deep links (`wa.me`) for vendor and support contact |

### Key Features

- 🏪 **Vendor storefronts** — business profile, logo, cover, products, WhatsApp contact
- 🛒 **Shopping cart** — per-user, synced with Supabase; local fallback when offline
- 💾 **Saved / Wishlist** — authenticated save per product
- 🔍 **Search & Explore** — by keyword and category
- 📦 **Preorders** — vendors can flag products as preorder-only
- 📊 **Analytics** — storefront views, product views, WhatsApp click tracking
- 🛡️ **Admin panel** — vendor verification, reports, platform settings
- 🌙 **Dark / Light / System theme** + adjustable text size
- 📴 **Offline support** — app shell cached by service worker

---

## 2. Directory Tree

```
jalsa-market-/
├── index.html              # Entire application (SPA — HTML + CSS + JS in one file)
├── sw.js                   # Service Worker (PWA offline caching)
├── manifest.webmanifest    # PWA Web App Manifest
├── supabase_schema.sql     # Full PostgreSQL schema + RLS policies + helper functions
├── SUPABASE_SETUP.md       # Step-by-step Supabase project setup guide
├── PROJECT_STRUCTURE.md    # This file
├── jalsa logo.png          # App favicon / brand logo
└── icons/
    ├── icon-192.png        # PWA icon — 192 × 192 (any purpose)
    └── icon-512.png        # PWA icon — 512 × 512 (any + maskable)
```

> **Note:** There are no `node_modules`, build tools, or package managers — this project intentionally ships as a **zero-build, zero-dependency** static web app. The only runtime external dependency is the Supabase JS client, loaded from jsDelivr CDN via a dynamic `import()`.

---

## 3. Architecture & Key Modules

This application is a **single-file SPA** (`index.html`). All CSS, HTML templates, and JavaScript live in that one file, divided into clearly numbered sections:

```
index.html
├── <head>              Metadata, PWA links, Google Fonts
├── <style>             Complete CSS design system (~600 lines)
│   ├── § 1  Design tokens (CSS custom properties: colours, radii, fonts, spacing)
│   ├── § 2  Reset / base styles
│   ├── § 3  Typography classes
│   ├── § 4  Layout utilities (container, section, flex helpers)
│   ├── § 5  Button variants
│   ├── § 6  Form elements
│   ├── § 7  Cards (vendor, product)
│   ├── § 8  Navigation (header, tab bar, bottom nav)
│   └── ...  Sheets, toasts, skeletons, admin UI, etc.
└── <script type="module">  Application logic (~2 500 lines)
    ├── § 0  CONFIG            — Supabase URL/key, support WhatsApp, pagination
    ├── § 1  UTILITIES         — DOM helpers ($, $$), money formatter, slugify, toast, sheet
    ├── § 2  STATE             — Global reactive state object (session, profile, cart, etc.)
    ├── § 3  SUPABASE CLIENT   — Dynamic import & createClient initialisation
    ├── § 4  API LAYER         — All Supabase query functions (categories, vendors, products,
    │                            saved, cart, analytics, announcements, admin)
    ├── § 5  AUTH              — customerSignup, vendorSignup, loginByNameAndPhone,
    │                            restoreSession, logout
    ├── § 6  RENDER — AUTH     — Login / signup screens
    ├── § 7  RENDER — HEADER & TABBAR
    ├── § 8  RENDER — SKELETONS (loading placeholders)
    ├── § 9  ROUTER            — Hash-based client-side routing (parseRoute → router())
    ├── § 10 RENDER — HOME     — Featured vendors, food vendors, products, event banner
    ├── § 11 RENDER — EXPLORE  — Search + category filter grid
    ├── § 12 RENDER — SAVED    — Wishlist view
    ├── § 13 RENDER — CART     — Cart items, totals, WhatsApp checkout
    ├── § 14 RENDER — ME       — User profile page
    ├── § 15 RENDER — SETTINGS — Theme, text size, notifications
    ├── § 16 RENDER — PRODUCT  — Product detail sheet / full page
    ├── § 17 RENDER — STORE    — Vendor storefront
    ├── § 18 RENDER — VENDOR AREA — Vendor dashboard (dashboard, products, profile, analytics)
    ├── § 19 RENDER — ADMIN    — Admin panel (vendors, reports, settings, announcements)
    ├── § 20 FORM SUBMISSIONS  — Global submit/change event delegation
    └── § 21 BOOT             — App initialisation, service worker registration
```

### Hash-Based Routes

| Hash | View |
|---|---|
| `#/home` | Home feed |
| `#/explore` | Search & browse |
| `#/saved` | Saved / wishlist |
| `#/cart` | Shopping cart |
| `#/me` | My profile |
| `#/settings` | Preferences |
| `#/product/:id` | Product detail |
| `#/store/:slug` | Vendor storefront |
| `#/vendor` | Vendor dashboard |
| `#/admin` | Admin panel (guarded) |
| `#/privacy` | Privacy policy |

### Database Schema (Supabase / PostgreSQL)

| Table | Purpose |
|---|---|
| `profiles` | Customer & vendor owner user records (linked to `auth.users`) |
| `vendors` | Vendor business profiles (status: `pending` / `approved` / `suspended`) |
| `categories` | Product categories (slug-based, sortable) |
| `events` | Jalsa event instances (active event drives banners) |
| `announcements` | Platform-wide broadcast messages |
| `products` | Vendor product listings (price, availability, preorder flag) |
| `product_images` | Storage paths for product photos (sorted) |
| `saved_products` | Customer wishlist (composite PK: customer + product) |
| `carts` / `cart_items` | Per-customer cart with price snapshot |
| `storefront_views` | Vendor page view analytics |
| `product_views` | Product detail view analytics |
| `whatsapp_clicks` | WhatsApp button click analytics |
| `user_consents` | GDPR/marketing consent log |
| `admin_users` | Admin user UUID allowlist |
| `vendor_verification_logs` | Audit trail for vendor status changes |
| `reports` | User-submitted content reports |
| `platform_settings` | Key-value store for platform-wide config |

Row Level Security (RLS) is enabled on all tables. A `jalsa_lookup_login` SQL function (security definer) handles name+phone login lookups without exposing other users' data.

### Service Worker (`sw.js`)

Implements a **network-first, cache-fallback** strategy:

1. **Install** — pre-caches the app shell (`index.html`, logo, icons, manifest).
2. **Activate** — purges stale caches.
3. **Fetch** — tries the network first; on failure serves the cache; falls back to `index.html` for navigation requests.

---

## 4. Setup & Execution

### Prerequisites

- A modern web browser (Chrome, Edge, Firefox, Safari)
- A [Supabase](https://supabase.com) account and project
- A static file server (or any HTTP server) to serve the files locally

> **No Node.js, npm, or build step is required.** This is a pure static site.

---

### Environment / Configuration

There is no `.env` file. Configuration is set directly in the `CONFIG` object near the top of `index.html` (around line 615):

```js
const CONFIG = {
  SUPABASE_URL:      'https://<your-project-ref>.supabase.co',  // ← Project URL
  SUPABASE_ANON_KEY: '<your-publishable-anon-key>',              // ← Anon/public key (safe for browser)
  VENDOR_GROUP_URL:  '<whatsapp-group-invite-link>',
  SUPPORT_WHATSAPP:  '<international-phone-number>',             // e.g. 2349012345678
  SPLASH_MS:         3200,   // Splash screen duration in ms
  PAGE_SIZE:         12,     // Pagination page size
  ADMIN_PATH:        '<secret-admin-url-segment>',               // Protects /admin route
};
```

> [!CAUTION]
> **Never** put the Supabase `service_role` key here — only use the `anon`/publishable key. The service role key has unrestricted database access and must never be exposed in a browser app.

> [!IMPORTANT]
> To run a local preview without a Supabase project, leave `SUPABASE_URL` and `SUPABASE_ANON_KEY` empty. The app will fall back to `localStorage`-based demo mode.

---

### Supabase Setup

Follow the full guide in [`SUPABASE_SETUP.md`](./SUPABASE_SETUP.md). Summary:

1. **Create a Supabase project** at [supabase.com](https://supabase.com).
2. **Copy** the Project URL and anon key → paste into `CONFIG` in `index.html`.
3. **Run the schema** — open the Supabase SQL Editor and execute `supabase_schema.sql`.
4. **Enable Email Auth** — Supabase Dashboard → Authentication → Providers → Email (OTP / Magic Link).
5. **Add URL config** — add your deployed site URL and `http://localhost:4173` as allowed redirect URLs.
6. **Create storage buckets** — `vendor-logos`, `store-covers`, `product-images` (all public).
7. **Seed data** — add categories, an active event, and platform settings via the dashboard.
8. **Create an admin** — insert an `auth.users` UUID into the `admin_users` table.

---

### Running Locally

Since there is no build step, you just need to serve the files over HTTP (not `file://`, as ES modules require a server origin).

**Option A — Python (built-in, zero install):**
```bash
# From the project root
python -m http.server 4173
# Then open: http://localhost:4173
```

**Option B — Node.js `serve` package:**
```bash
npx serve . -p 4173
# Then open: http://localhost:4173
```

**Option C — VS Code Live Server extension:**
- Right-click `index.html` → *Open with Live Server*

**Option D — Any static hosting:**
Deploy the files to GitHub Pages, Netlify, Vercel, Cloudflare Pages, or any HTTPS host. The PWA install prompt requires HTTPS.

---

### PWA Installation

Once hosted over HTTPS, users can install the app to their home screen:

- **Android (Chrome):** tap the "Add to Home Screen" banner or use the browser menu.
- **iOS (Safari):** tap Share → Add to Home Screen.
- **Desktop (Chrome/Edge):** click the install icon in the address bar.

---

### Testing

There is no automated test suite currently. Manual testing checklist (from `SUPABASE_SETUP.md`):

- [ ] Vendor signup creates a profile and pending vendor record
- [ ] Vendor login resolves the owned vendor via `auth.uid()`
- [ ] Customer login creates or restores only the signed-in user's profile
- [ ] RLS prevents one user editing another user's vendor, cart, or saved products
- [ ] Product images save under the correct Supabase storage bucket
- [ ] PWA can install and relaunch offline
- [ ] Logout clears the Supabase session and local demo state

---

### Deployment Checklist

- [ ] Set real Supabase URL and anon key in `CONFIG`
- [ ] Run `supabase_schema.sql` and apply RLS policies
- [ ] Configure storage buckets and access policies
- [ ] Set `ADMIN_PATH` to a non-guessable string
- [ ] Deploy over HTTPS
- [ ] Add deployed domain to Supabase Auth URL configuration
- [ ] Test on physical Android and iOS devices

---

*Generated automatically — do not edit by hand.*
