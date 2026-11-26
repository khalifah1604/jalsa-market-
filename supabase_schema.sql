create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  phone text,
  is_vendor boolean default false,
  marketing_consent boolean default false,
  consent_at timestamptz,
  account_status text default 'active',
  created_at timestamptz default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  is_active boolean default true,
  sort_order integer default 0
);

create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete set null,
  business_name text not null,
  slug text not null unique,
  business_category text,
  category_id uuid references public.categories(id),
  state text,
  district text,
  local_jamaat text,
  participation_type text,
  stall_number text,
  description text,
  whatsapp_number text,
  logo_path text,
  cover_path text,
  status text default 'pending',
  accepts_preorders boolean default false,
  preorder_details text,
  collection_info text,
  jalsa_availability text,
  is_featured boolean default false,
  verified_at timestamptz,
  suspended_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  starts_on timestamptz,
  ends_on timestamptz,
  is_active boolean default true,
  details jsonb default '{}'::jsonb
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  published_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid references public.vendors(id) on delete cascade,
  category_id uuid references public.categories(id),
  name text not null,
  slug text,
  description text,
  price numeric(12,2) default 0,
  currency text default 'NGN',
  is_available boolean default true,
  is_preorder boolean default false,
  stock_count integer,
  created_at timestamptz default now()
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete cascade,
  storage_path text not null,
  sort_order integer default 0
);

create table if not exists public.saved_products (
  customer_id uuid references auth.users(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (customer_id, product_id)
);

create table if not exists public.carts (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid unique references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid references public.carts(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  quantity integer default 1,
  price_snapshot numeric(12,2) default 0
);

create table if not exists public.storefront_views (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid references public.vendors(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.product_views (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.whatsapp_clicks (
  id uuid primary key default gen_random_uuid(),
  target_type text,
  target_id text,
  payload jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  consent_type text,
  granted boolean,
  created_at timestamptz default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create table if not exists public.vendor_verification_logs (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid references public.vendors(id) on delete cascade,
  action text,
  created_at timestamptz default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  target_type text,
  target_id uuid,
  reason text,
  status text default 'open',
  created_at timestamptz default now()
);

create table if not exists public.platform_settings (
  key text primary key,
  value jsonb
);

alter table public.profiles enable row level security;
alter table public.vendors enable row level security;
alter table public.categories enable row level security;
alter table public.events enable row level security;
alter table public.announcements enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.saved_products enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.storefront_views enable row level security;
alter table public.product_views enable row level security;
alter table public.whatsapp_clicks enable row level security;
alter table public.user_consents enable row level security;
alter table public.reports enable row level security;

create policy "Public read approved vendors" on public.vendors
  for select using (status = 'approved');

create policy "Owner read vendor" on public.vendors
  for select using (auth.uid() = owner_id);

create policy "Owner update vendor" on public.vendors
  for update using (auth.uid() = owner_id);

create policy "Vendor create own record" on public.vendors
  for insert with check (auth.uid() = owner_id);

create policy "Public read categories" on public.categories for select using (is_active);
create policy "Public read events" on public.events for select using (is_active);
create policy "Public read announcements" on public.announcements for select using (published_at is not null);

create policy "Public read products" on public.products
  for select using (is_available and exists (
    select 1 from public.vendors v
    where v.id = vendor_id and v.status = 'approved'
  ));

create policy "Vendor manage products" on public.products
  for all using (exists (
    select 1 from public.vendors v
    where v.id = vendor_id and v.owner_id = auth.uid()
  ));

create policy "Public read product images" on public.product_images
  for select using (true);

create policy "Vendor manage product images" on public.product_images
  for all using (exists (
    select 1 from public.products p
    join public.vendors v on v.id = p.vendor_id
    where p.id = product_id and v.owner_id = auth.uid()
  ));

create policy "User read profile" on public.profiles
  for select using (auth.uid() = id);

create policy "User update profile" on public.profiles
  for update using (auth.uid() = id);

create policy "User create profile" on public.profiles
  for insert with check (auth.uid() = id);

create policy "User manage saved products" on public.saved_products
  for all using (auth.uid() = customer_id);

create policy "User manage carts" on public.carts
  for all using (auth.uid() = customer_id);

create policy "User manage cart items" on public.cart_items
  for all using (exists (
    select 1 from public.carts c
    where c.id = cart_id and c.customer_id = auth.uid()
  ));

create policy "Authenticated log consent" on public.user_consents
  for insert with check (auth.uid() = user_id);

-- ============================================================
-- ADMIN ROLE, SECURITY DEFINER & RLS POLICIES
-- ============================================================

-- Function to safely verify if the current authenticated caller is an admin
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users where user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Enable RLS on admin-relevant tables
alter table public.admin_users enable row level security;
alter table public.vendor_verification_logs enable row level security;
alter table public.platform_settings enable row level security;

-- Policies for admin_users
create policy "Users can check own admin status" on public.admin_users
  for select using (auth.uid() = user_id);

create policy "Admins can view all admin users" on public.admin_users
  for select using (public.is_admin());

-- Admin policies for vendors
create policy "Admins can view all vendors" on public.vendors
  for select using (public.is_admin());

create policy "Admins can update all vendors" on public.vendors
  for update using (public.is_admin());

-- Admin policies for vendor verification logs
create policy "Admins can view verification logs" on public.vendor_verification_logs
  for select using (public.is_admin());

create policy "Admins can insert verification logs" on public.vendor_verification_logs
  for insert with check (public.is_admin());

-- Admin policies for products
create policy "Admins can view all products" on public.products
  for select using (public.is_admin());

create policy "Admins can update all products" on public.products
  for update using (public.is_admin());

-- Admin policies for product images
create policy "Admins can manage product images" on public.product_images
  for all using (public.is_admin());

-- Admin policies for profiles (allows admin dashboard customer counts & marketing exports)
create policy "Admins can view all profiles" on public.profiles
  for select using (public.is_admin());

-- Admin policies for reports
create policy "Admins can manage reports" on public.reports
  for all using (public.is_admin());

create policy "Authenticated can insert reports" on public.reports
  for insert with check (auth.role() = 'authenticated');

-- Admin policies for categories, events, announcements
create policy "Admins can manage categories" on public.categories
  for all using (public.is_admin());

create policy "Admins can manage events" on public.events
  for all using (public.is_admin());

create policy "Admins can manage announcements" on public.announcements
  for all using (public.is_admin());

-- Admin policies for platform settings
create policy "Admins can manage platform settings" on public.platform_settings
  for all using (public.is_admin());

create policy "Public can read platform settings" on public.platform_settings
  for select using (true);

-- Helper procedure to easily grant admin role by email (run from Supabase SQL Editor)
create or replace function public.seed_admin_by_email(p_email text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
begin
  select id into target_user_id from auth.users where lower(email) = lower(trim(p_email));
  if target_user_id is null then
    return 'User with email "' || p_email || '" not found in auth.users. Please sign up or log in first.';
  end if;

  insert into public.admin_users (user_id)
  values (target_user_id)
  on conflict (user_id) do nothing;

  return 'Success: ' || p_email || ' (User ID: ' || target_user_id || ') is now an Administrator.';
end;
$$;

-- Direct login authentication without sending an email OTP on sign in
create or replace function public.jalsa_authenticate_login(
  p_role text,
  p_name text,
  p_phone text
)
returns table (
  id uuid,
  full_name text,
  email text,
  phone text,
  is_vendor boolean,
  auth_token text
)
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_user_id uuid;
  v_email text;
  v_full_name text;
  v_phone text;
  v_is_vendor boolean;
  v_pass text;
begin
  if p_role = 'vendor' then
    select p.id, p.full_name, p.email, p.phone, coalesce(p.is_vendor, true)
    into v_user_id, v_full_name, v_email, v_phone, v_is_vendor
    from public.profiles p
    join public.vendors v on v.owner_id = p.id
    where (lower(trim(v.whatsapp_number)) = lower(trim(p_phone)) or lower(trim(p.phone)) = lower(trim(p_phone)))
      and (lower(trim(v.business_name)) = lower(trim(p_name)) or lower(trim(p.full_name)) = lower(trim(p_name)))
    limit 1;
  else
    select p.id, p.full_name, p.email, p.phone, coalesce(p.is_vendor, false)
    into v_user_id, v_full_name, v_email, v_phone, v_is_vendor
    from public.profiles p
    where lower(trim(p.phone)) = lower(trim(p_phone))
      and lower(trim(p.full_name)) = lower(trim(p_name))
    limit 1;
  end if;

  if v_user_id is null then
    return;
  end if;

  -- Deterministic password for direct password sign-in (never triggers email service)
  v_pass := 'Jalsa@' || replace(v_user_id::text, '-', '');

  -- Ensure the user has this password set in auth.users
  update auth.users
  set encrypted_password = crypt(v_pass, gen_salt('bf'))
  where auth.users.id = v_user_id;

  return query select v_user_id, v_full_name, v_email, v_phone, v_is_vendor, v_pass;
end;
$$;

revoke all on function public.jalsa_authenticate_login(text, text, text) from public;
grant execute on function public.jalsa_authenticate_login(text, text, text) to anon, authenticated;

create or replace function public.jalsa_lookup_login(
  p_role text,
  p_name text,
  p_phone text
)
returns table (
  id uuid,
  email text,
  full_name text,
  phone text,
  is_vendor boolean
)
language sql
security definer
set search_path = public
as $$
  select p.id, p.email, p.full_name, p.phone, coalesce(p.is_vendor, false)
  from public.profiles p
  where lower(trim(p.phone)) = lower(trim(p_phone))
    and (
      (p_role = 'user' and lower(trim(p.full_name)) = lower(trim(p_name)))
      or
      (p_role = 'vendor' and exists (
        select 1
        from public.vendors v
        where v.owner_id = p.id
          and lower(trim(v.business_name)) = lower(trim(p_name))
      ))
    )
  limit 1;
$$;

revoke all on function public.jalsa_lookup_login(text, text, text) from public;
grant execute on function public.jalsa_lookup_login(text, text, text) to anon, authenticated;

-- ============================================================
-- STORAGE BUCKETS & POLICIES
-- ============================================================
insert into storage.buckets (id, name, public)
values
  ('vendor-logos', 'vendor-logos', true),
  ('store-covers', 'store-covers', true),
  ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

-- Public read access for images
create policy "Public view vendor-logos"
  on storage.objects for select
  using (bucket_id = 'vendor-logos');

create policy "Public view store-covers"
  on storage.objects for select
  using (bucket_id = 'store-covers');

create policy "Public view product-images"
  on storage.objects for select
  using (bucket_id = 'product-images');

-- Authenticated upload access
create policy "Authenticated upload vendor-logos"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'vendor-logos');

create policy "Authenticated upload store-covers"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'store-covers');

create policy "Authenticated upload product-images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'product-images');

-- Authenticated update access
create policy "Authenticated update vendor-logos"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'vendor-logos');

create policy "Authenticated update store-covers"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'store-covers');

create policy "Authenticated update product-images"
  on storage.objects for update
  using (bucket_id = 'product-images');

-- ============================================================
-- ADMIN LOGIN WITHOUT EMAIL
-- The email provider is disabled in this project, so the admin
-- form signs in anonymously, then calls jalsa_claim_admin() which
-- bcrypt-verifies p_secret and grants admin_users for auth.uid().
-- To rotate the password: edit the seed below and re-run it.
-- ============================================================
create table if not exists public.admin_secrets (
  id boolean primary key default true check (id),
  secret_hash text not null
);

alter table public.admin_secrets enable row level security;
revoke all on table public.admin_secrets from anon, authenticated;

set search_path to public, extensions, auth;

insert into public.admin_secrets (id, secret_hash)
values (true, crypt('p@$$worD', gen_salt('bf')))
on conflict (id) do update set secret_hash = excluded.secret_hash;

create or replace function public.jalsa_claim_admin(p_secret text)
returns boolean
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_hash text;
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return false;
  end if;

  select secret_hash into v_hash from public.admin_secrets where id = true;
  if v_hash is null or crypt(p_secret, v_hash) is distinct from v_hash then
    return false;
  end if;

  insert into public.profiles (id, full_name, is_vendor)
  values (v_uid, 'Administrator', false)
  on conflict (id) do nothing;

  insert into public.admin_users (user_id)
  values (v_uid)
  on conflict (user_id) do nothing;

  return true;
end;
$$;

revoke all on function public.jalsa_claim_admin(text) from public;
grant execute on function public.jalsa_claim_admin(text) to anon, authenticated;

-- ============================================================
-- CATEGORY DISCOVERY UPGRADE
-- Run this block once in the Supabase SQL Editor. It is idempotent:
-- re-running will not duplicate categories or overwrite existing
-- category links that are already set.
-- ============================================================

-- 1. Seed the canonical categories used by the marketplace.
insert into public.categories (name, slug, sort_order, is_active) values
  ('Food & Snacks',        'food-snacks',        10, true),
  ('Fashion',              'fashion',            20, true),
  ('Books',                'books',              30, true),
  ('Beauty',               'beauty',             40, true),
  ('Electronics',          'electronics',        50, true),
  ('Accessories',          'accessories',        60, true),
  ('Shoes',                'shoes',              70, true),
  ('Perfumes',             'perfumes',           80, true),
  ('Islamic Products',     'islamic-products',   90, true),
  ('Home & Lifestyle',     'home-lifestyle',    100, true),
  ('Phones & Accessories', 'phones-accessories', 110, true),
  ('Gifts',                'gifts',             120, true),
  ('Groceries',            'groceries',         130, true),
  ('Services',             'services',          140, true),
  ('Baby & Kids',          'baby-kids',         150, true),
  ('Sports & Fitness',     'sports-fitness',    160, true),
  ('Art & Crafts',         'art-crafts',        170, true),
  ('Other',                'other',             180, true),
  ('Fabrics & Textiles',   'fabrics-textiles',   190, true),
  ('Jewelry & Watches',    'jewelry-watches',    200, true),
  ('Stationery',           'stationery',         210, true),
  ('Toys & Games',         'toys-games',         220, true)
on conflict (slug) do nothing;

-- 2. Backfill vendors that only have the legacy text category.
update public.vendors v
set category_id = c.id
from public.categories c
where v.category_id is null
  and v.business_category is not null
  and (lower(v.business_category) = lower(c.name) or lower(v.business_category) = lower(c.slug));

-- 3. Keep the legacy text column in sync for anything linked by id.
update public.vendors v
set business_category = c.name
from public.categories c
where v.category_id = c.id
  and (v.business_category is null or v.business_category <> c.name);

-- 4. Products inherit their vendor's category when they have none.
update public.products p
set category_id = v.category_id
from public.vendors v
where p.vendor_id = v.id
  and p.category_id is null
  and v.category_id is not null;

-- 5. Indexes for the browse-by-category queries.
create index if not exists vendors_status_category_idx on public.vendors (status, category_id);
create index if not exists vendors_featured_idx on public.vendors (is_featured, created_at desc);
create index if not exists products_vendor_category_idx on public.products (vendor_id, category_id);
create index if not exists products_category_created_idx on public.products (category_id, created_at desc);

-- 6. Vendor counts per category (used for chip counts on Home/Explore).
create or replace function public.jalsa_vendor_counts()
returns table (category_id uuid, vendor_count bigint)
language sql
security definer
stable
set search_path = public
as $$
  select v.category_id, count(*)::bigint
  from public.vendors v
  where v.status = 'approved' and v.category_id is not null
  group by v.category_id;
$$;

revoke all on function public.jalsa_vendor_counts() from public;
grant execute on function public.jalsa_vendor_counts() to anon, authenticated;

-- 7. Discovery feed: at most p_per_vendor products per vendor so one store
--    cannot flood the home/explore grids. Returns product ids in display order.
create or replace function public.jalsa_discover_products(
  p_per_vendor integer default 1,
  p_limit integer default 12,
  p_category_id uuid default null,
  p_search text default null
)
returns table (product_id uuid, sort_at timestamptz)
language sql
security definer
stable
set search_path = public
as $$
  select ranked.id, ranked.created_at
  from (
    select p.id, p.created_at,
           row_number() over (partition by p.vendor_id order by p.created_at desc) as rn
    from public.products p
    join public.vendors v on v.id = p.vendor_id
    where v.status = 'approved'
      and p.is_available
      and (p_category_id is null or p.category_id = p_category_id)
      and (p_search is null or p_search = '' or p.name ilike '%' || p_search || '%')
  ) ranked
  where ranked.rn <= greatest(p_per_vendor, 1)
  order by ranked.created_at desc
  limit greatest(p_limit, 1);
$$;

revoke all on function public.jalsa_discover_products(integer, integer, uuid, text) from public;
grant execute on function public.jalsa_discover_products(integer, integer, uuid, text) to anon, authenticated;

-- ============================================================
-- WHATSAPP ORDER TRACKING UPGRADE
-- ------------------------------------------------------------
-- Orders are completed on WhatsApp, so this records the handoff
-- (an "order request") and lets the vendor confirm or cancel it
-- in their dashboard. Only confirmed rows count as a sale.
-- Safe to run on its own; does not touch existing data.
-- ============================================================

-- 1. Let the public log lightweight analytics events. RLS is
--    enabled on these tables but previously had no INSERT policy.
drop policy if exists "Anyone can log storefront view" on public.storefront_views;
create policy "Anyone can log storefront view" on public.storefront_views
  for insert with check (true);

drop policy if exists "Anyone can log product view" on public.product_views;
create policy "Anyone can log product view" on public.product_views
  for insert with check (true);

drop policy if exists "Anyone can log whatsapp click" on public.whatsapp_clicks;
create policy "Anyone can log whatsapp click" on public.whatsapp_clicks
  for insert with check (true);

-- 2. Vendors can read their own analytics, admins can read all.
drop policy if exists "Vendors read own storefront views" on public.storefront_views;
create policy "Vendors read own storefront views" on public.storefront_views
  for select using (exists (
    select 1 from public.vendors v
    where v.id = vendor_id and v.owner_id = auth.uid()
  ));

drop policy if exists "Vendors read own product views" on public.product_views;
create policy "Vendors read own product views" on public.product_views
  for select using (exists (
    select 1 from public.products p
    join public.vendors v on v.id = p.vendor_id
    where p.id = product_id and v.owner_id = auth.uid()
  ));

drop policy if exists "Vendors read own whatsapp clicks" on public.whatsapp_clicks;
create policy "Vendors read own whatsapp clicks" on public.whatsapp_clicks
  for select using (exists (
    select 1 from public.vendors v
    where v.id::text = target_id and v.owner_id = auth.uid()
  ));

drop policy if exists "Admins read storefront views" on public.storefront_views;
create policy "Admins read storefront views" on public.storefront_views
  for select using (public.is_admin());

drop policy if exists "Admins read product views" on public.product_views;
create policy "Admins read product views" on public.product_views
  for select using (public.is_admin());

drop policy if exists "Admins read whatsapp clicks" on public.whatsapp_clicks;
create policy "Admins read whatsapp clicks" on public.whatsapp_clicks
  for select using (public.is_admin());

-- 3. Order handoff table. One row per WhatsApp checkout request.
create table if not exists public.order_intents (
  id uuid primary key default gen_random_uuid(),
  order_code text not null,
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  customer_id uuid references auth.users(id) on delete set null,
  customer_key text not null,
  customer_name text,
  customer_phone text,
  items jsonb not null default '[]'::jsonb,
  item_count integer not null default 0,
  subtotal numeric(12,2) not null default 0,
  status text not null default 'initiated'
    check (status in ('initiated', 'confirmed', 'cancelled')),
  source text not null default 'whatsapp',
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);

create index if not exists order_intents_vendor_idx
  on public.order_intents (vendor_id, created_at desc);
create index if not exists order_intents_customer_idx
  on public.order_intents (customer_key);
create index if not exists order_intents_status_idx
  on public.order_intents (status);

alter table public.order_intents enable row level security;

drop policy if exists "Anyone can log order intent" on public.order_intents;
create policy "Anyone can log order intent" on public.order_intents
  for insert with check (true);

drop policy if exists "Vendors read own order intents" on public.order_intents;
create policy "Vendors read own order intents" on public.order_intents
  for select using (exists (
    select 1 from public.vendors v
    where v.id = vendor_id and v.owner_id = auth.uid()
  ));

drop policy if exists "Vendors update own order intents" on public.order_intents;
create policy "Vendors update own order intents" on public.order_intents
  for update using (exists (
    select 1 from public.vendors v
    where v.id = vendor_id and v.owner_id = auth.uid()
  )) with check (exists (
    select 1 from public.vendors v
    where v.id = vendor_id and v.owner_id = auth.uid()
  ));

drop policy if exists "Admins manage order intents" on public.order_intents;
create policy "Admins manage order intents" on public.order_intents
  for all using (public.is_admin()) with check (public.is_admin());

grant select, insert, update on public.order_intents to anon, authenticated;

-- 4. Exact per-vendor stats for the vendor dashboard.
create or replace function public.jalsa_vendor_stats()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  with me as (
    select id from public.vendors where owner_id = auth.uid() limit 1
  )
  select jsonb_build_object(
    'storefront_views', (
      select count(*) from public.storefront_views
      where vendor_id = (select id from me)
    ),
    'product_views', (
      select count(*) from public.product_views pv
      join public.products p on p.id = pv.product_id
      where p.vendor_id = (select id from me)
    ),
    'whatsapp_clicks', (
      select count(*) from public.whatsapp_clicks
      where target_type = 'storefront_contact'
        and target_id = (select id::text from me)
    ),
    'order_requests', (
      select count(*) from public.order_intents
      where vendor_id = (select id from me)
    ),
    'confirmed_orders', (
      select count(*) from public.order_intents
      where vendor_id = (select id from me) and status = 'confirmed'
    ),
    'unique_customers', (
      select count(distinct coalesce(customer_key, customer_phone, id::text))
      from public.order_intents
      where vendor_id = (select id from me) and status <> 'cancelled'
    ),
    'confirmed_revenue', (
      select coalesce(sum(subtotal), 0) from public.order_intents
      where vendor_id = (select id from me) and status = 'confirmed'
    )
  );
$$;

revoke all on function public.jalsa_vendor_stats() from public;
revoke all on function public.jalsa_vendor_stats() from anon;
grant execute on function public.jalsa_vendor_stats() to authenticated;

-- 5. Admin view: orders + unique customers per vendor.
create or replace function public.jalsa_admin_vendor_orders()
returns table (
  vendor_id uuid,
  business_name text,
  order_requests bigint,
  confirmed_orders bigint,
  unique_customers bigint,
  confirmed_revenue numeric
)
language sql
security definer
stable
set search_path = public
as $$
  select v.id,
         v.business_name,
         count(o.id) as order_requests,
         count(o.id) filter (where o.status = 'confirmed') as confirmed_orders,
         count(distinct coalesce(o.customer_key, o.customer_phone, o.id::text))
           filter (where o.status <> 'cancelled') as unique_customers,
         coalesce(sum(o.subtotal) filter (where o.status = 'confirmed'), 0) as confirmed_revenue
  from public.vendors v
  left join public.order_intents o on o.vendor_id = v.id
  where public.is_admin()
  group by v.id, v.business_name
  order by count(o.id) desc, v.business_name;
$$;

revoke all on function public.jalsa_admin_vendor_orders() from public;
revoke all on function public.jalsa_admin_vendor_orders() from anon;
grant execute on function public.jalsa_admin_vendor_orders() to authenticated;

-- ============================================================
-- ANTI-JUNK / ACCOUNT-SAFETY HARDENING (safe for existing data)
-- ------------------------------------------------------------
-- * constraints are added NOT VALID: they are enforced on all NEW
--   writes but existing rows are not retroactively rejected.
-- * run the AUDIT queries first; then (optionally) VALIDATE CONSTRAINT.
-- * paired with app-side validation in index.html. Re-runnable.
-- * NOTE: requires a letter/digit in a name -> blocks punctuation-only
--   junk like '.....'. It does NOT block a *valid* phone such as
--   08012345678; junk is stopped via name + validation + moderation.
-- ============================================================

-- ---- profiles -------------------------------------------------
alter table public.profiles alter column account_status set default 'active';
alter table public.profiles drop constraint if exists profiles_account_status_ok;
alter table public.profiles add constraint profiles_account_status_ok check (
  account_status is not null
  and account_status in ('active', 'pending', 'blocked', 'suspended', 'banned')
) not valid;

alter table public.profiles drop constraint if exists profiles_full_name_ok;
alter table public.profiles add constraint profiles_full_name_ok check (
  full_name is not null
  and length(trim(full_name)) >= 1
  and trim(full_name) ~ '[[:alnum:]]'                         -- requires a letter/digit; '.....' rejected
) not valid;

alter table public.profiles drop constraint if exists profiles_phone_ok;
alter table public.profiles add constraint profiles_phone_ok check (
  phone is null                                                       -- phoneless profile is harmless...
  or length(regexp_replace(phone, '\D', '', 'g')) between 7 and 15    -- ...but if present, must be 7-15 digits
) not valid;
-- NOTE: phone PRESENCE is enforced app-side + in `User create profile`, NOT at table level,
--       so `jalsa_claim_admin` (admin seeding, inserts a phoneless profile) keeps working.

-- normalise trivial whitespace on existing names (safe); does NOT invent data
update public.profiles
  set full_name = trim(regexp_replace(full_name, '\s+', ' ', 'g'))
  where full_name is not null and full_name <> trim(regexp_replace(full_name, '\s+', ' ', 'g'));

-- ---- vendors --------------------------------------------------
alter table public.vendors drop constraint if exists vendors_business_name_ok;
alter table public.vendors add constraint vendors_business_name_ok check (
  business_name is not null
  and length(trim(business_name)) >= 1
  and trim(business_name) ~ '[[:alnum:]]'
) not valid;

-- ---- AUDIT (read-only; run before VALIDATE CONSTRAINT) --------
--   select id, full_name, phone, account_status from public.profiles
--    where full_name is null or trim(full_name)='' or trim(full_name) !~ '[[:alnum:]]'
--       or phone is null or length(regexp_replace(coalesce(phone,''),'\D','','g')) not between 7 and 15
--       or account_status is null or account_status not in ('active','pending','blocked','suspended','banned');
--   select trim(lower(full_name)) as name, count(*) from public.profiles
--    group by 1 having count(*) > 1 order by 2 desc;                                                   -- dup names
--   select regexp_replace(coalesce(phone,''),'\D','','g') d, count(*) from public.profiles
--    group by 1 having count(*) > 1 order by 2 desc;                                                    -- dup phones
--   select id, business_name from public.vendors where business_name is null or trim(business_name)='' or trim(business_name) !~ '[[:alnum:]]';
--   -- then e.g.:
--   -- alter table public.profiles validate constraint profiles_full_name_ok;
--   -- alter table public.profiles validate constraint profiles_phone_ok;
--   -- alter table public.profiles validate constraint profiles_account_status_ok;
--   -- alter table public.vendors   validate constraint vendors_business_name_ok;
--
-- OPTIONAL (only if audit shows no duplicates; protects the name+phone login model):
--   create unique index if not exists profiles_phone_unique
--     on public.profiles ( (right(regexp_replace(phone, '\D', '', 'g'), 10)) );   -- last-10 key, NG-aware

-- ---- privileged-column protection ----------------------------
-- owners/users may edit their own rows but not self-escalate / self-unblock.
create or replace function public.guard_profiles_privileged() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    if new.id is distinct from old.id
       or new.account_status is distinct from old.account_status then
      raise exception 'not allowed to change protected profile fields';
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists guard_profiles_privileged on public.profiles;
create trigger guard_profiles_privileged
  before update on public.profiles
  for each row execute function public.guard_profiles_privileged();

create or replace function public.guard_vendor_privileged() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    if new.id is distinct from old.id
       or new.owner_id is distinct from old.owner_id
       or new.status is distinct from old.status          -- admin-only approval (you approve vendors)
       or new.is_featured is distinct from old.is_featured
       or new.verified_at is distinct from old.verified_at
       or new.suspended_at is distinct from old.suspended_at then
      raise exception 'not allowed to change protected vendor fields';
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists guard_vendor_privileged on public.vendors;
create trigger guard_vendor_privileged
  before update on public.vendors
  for each row execute function public.guard_vendor_privileged();

-- ---- RLS hardening -------------------------------------------
-- profiles: own row; trigger blocks self-escalation; admins may update.
drop policy if exists "User update profile" on public.profiles;
create policy "User update profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Admins can update all profiles" on public.profiles;
create policy "Admins can update all profiles" on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());

-- profiles INSERT already `auth.uid()=id`; add safe-content checks.
drop policy if exists "User create profile" on public.profiles;
create policy "User create profile" on public.profiles
  for insert with check (
    auth.uid() = id
    and account_status = 'active'
    and full_name is not null and length(trim(full_name)) >= 1 and trim(full_name) ~ '[[:alnum:]]'
    and (phone is null or length(regexp_replace(phone, '\D', '', 'g')) between 7 and 15)
  );
-- NOTE: phone PRESENCE required by the app + name+phone login, not by RLS,
--       so `jalsa_claim_admin` (security definer; inserts phoneless admin profile) is unaffected.

-- vendors: owner can edit own content; cannot self-approve; admins (you) approve.
drop policy if exists "Owner update vendor" on public.vendors;
create policy "Owner update vendor" on public.vendors
  for update using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Vendor create own record" on public.vendors;
create policy "Vendor create own record" on public.vendors
  for insert with check (
    auth.uid() = owner_id
    and status = 'pending'                         -- starts pending; admin approves
    and is_featured = false
    and verified_at is null
    and suspended_at is null
    and business_name is not null and length(trim(business_name)) >= 1 and trim(business_name) ~ '[[:alnum:]]'
  );

-- keep "Admins can update all vendors" (is_admin) for approve/suspend; trigger exempts admins.

-- order intents: only signed-in customers, valid status/source, sane sizes, approved vendor.
drop policy if exists "Anyone can log order intent" on public.order_intents;
create policy "Customers can log order intent" on public.order_intents
  for insert with check (
    auth.role() = 'authenticated'
    and (customer_id is null or customer_id = auth.uid())
    and status = 'initiated'
    and source = 'whatsapp'
    and subtotal >= 0
    and item_count >= 0
    and length(coalesce(order_code, '')) between 1 and 64
    and length(coalesce(customer_name, '')) <= 120
    and length(coalesce(customer_phone, '')) <= 32
    and length(coalesce(customer_key, '')) <= 128
    and exists (select 1 from public.vendors v where v.id = vendor_id and v.status = 'approved')
  );
revoke insert on public.order_intents from anon;   -- ordering requires a signed-in (anonymous-auth) user

-- ---- remove unused, dangerous security-definer RPCs ----------
-- The app calls NONE of these; they are legacy email-OTP-era helpers.
-- `jalsa_authenticate_login` (security definer, granted anon) cross-user matches,
-- SETS a known deterministic password and RETURNS it; `jalsa_lookup_login`
-- (security definer, granted anon) leaks id/email/name/phone cross-user.
-- NOTE: admin seeding is intentionally LEFT UNTOUCHED
--       (`seed_admin_by_email`, `jalsa_claim_admin`, `admin_secrets`, `ADMIN_PATH`).
drop function if exists public.jalsa_authenticate_login(text, text, text);
drop function if exists public.jalsa_lookup_login(text, text, text);

-- ---- PII scrub on customer removal (order_intents keeps text copies) ----
-- order_intents.customer_id -> set null, but customer_name/customer_phone/customer_key remain.
-- Recommended after deleting a user (or for the junk customer below): scrub PII first.
--   delete from public.order_intents where customer_id = :uid or customer_key = :uid::text;


-- ============================================================
-- ONE-TIME PURGE: junk customer  name = '.....'  phone = '08012345678'
-- ------------------------------------------------------------
-- This is a *runbook*, COMMENTED OUT. It does NOT run when this file
-- is applied. Run it manually against PRODUCTION with service-role
-- (Supabase SQL Editor / a one-off server script; NEVER from the app;
-- never add service_role to CONFIG). Back up first. The app cannot
-- delete a user (no profiles DELETE policy; cannot delete auth.users).
-- NOTE: in production this row has is_vendor = true. A `vendors` row may exist
-- for it (pending/approved) + products; `vendors.owner_id -> SET NULL`, so
-- DELETE the vendor row first or it (and its products) would be orphaned.
-- Replace :uid with the profiles.id. Wrapped in a transaction.
--
-- 0) find it (read-only). name is literally '.....'; match phone last-10.
--    select id, full_name, phone, email, is_vendor, account_status, created_at
--    from public.profiles
--    where full_name = '.....'
--       or right(regexp_replace(coalesce(phone,''), '\D','','g'), 10) = '8012345678';
--    -- 08012345678 -> digits '08012345678' -> last-10 '8012345678'; +2348012345678 also matches.
--    -- then:  \set uid '<the-id>'
--
-- 1) inspect linked rows (read-only).
--    select * from public.order_intents where customer_id = :uid or customer_key = :uid::text
--      or right(regexp_replace(coalesce(customer_phone,''),'\D','','g'),10) = '8012345678';
--    select * from public.saved_products where customer_id = :uid;
--    select * from public.carts where customer_id = :uid;
--    select * from public.user_consents where user_id = :uid;
--    select * from public.admin_users where user_id = :uid;                 -- expect none (customer)
--    select id, owner_id, business_name, status from public.vendors where owner_id = :uid;  -- expect none
--    select * from public.whatsapp_clicks where payload->>'customer_key' = :uid::text;
--
-- 2) purge. order_intents has NO FK to profiles + keeps PII copies -> scrub first.
--    NOTE: this user has is_vendor=true. If a vendors row references this user it
--    would be SET NULL (not cascade) and its products would survive -> DELETE
--    the vendor row first (cascades products/product_images/order_intents-vendor).
--
-- begin;
--   delete from public.order_intents
--    where customer_id = :uid or customer_key = :uid::text
--       or right(regexp_replace(coalesce(customer_phone,''),'\D','','g'),10) = '8012345678';
--   delete from public.saved_products where customer_id = :uid;
--   delete from public.carts where customer_id = :uid;            -- cascades cart_items
--   delete from public.user_consents where user_id = :uid;
--   delete from public.admin_users where user_id = :uid;          -- no-op for a customer
--   delete from public.vendors where owner_id = :uid;             -- REQUIRED if is_vendor=true; cascades products; else SET NULL
--   delete from public.profiles where id = :uid;                  -- service-role only (no RLS delete policy)
--   delete from public.whatsapp_clicks where payload->>'customer_key' = :uid::text;  -- optional PII scrub
-- commit;
--
-- 3) delete the auth identity (removes auth.users + sessions/refresh tokens; cascades again).
--    PREFERRED:  supabase.auth.admin.deleteUser(:uid)   -- service-role admin API / Dashboard
--    (or, in SQL editor as service role, AFTER step 2:  delete from auth.users where id = :uid;)
--    FK order matters: vendors.owner_id -> set null; order_intents.customer_id -> set null;
--    everything else -> cascade. Delete vendors + scrub order_intents BEFORE deleting auth.users.
--
-- 4) verify.   select * from public.profiles where id = :uid;                                  -- 0 rows
--              select * from auth.users where id = :uid;                                       -- 0 rows
--              select * from public.order_intents where customer_id = :uid or customer_key=:uid::text
--                or right(regexp_replace(coalesce(customer_phone,''),'\D','','g'),10)='8012345678'; -- 0 rows
--              select * from public.vendors where owner_id is null;                            -- no orphans created
--
-- 5) on that customer's own device, clear app data (localStorage jalsa.*, sb-*-auth-token,
--    sessionStorage jalsa.pending.signup); a stale anonymous token then fails -> guest mode.
--    Server-side removal alone does not clear their browser.
