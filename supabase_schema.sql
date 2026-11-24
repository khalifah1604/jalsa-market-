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
