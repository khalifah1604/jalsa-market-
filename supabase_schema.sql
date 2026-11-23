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

create or replace function public.jalsa_lookup_login(
  p_role text,
  p_name text,
  p_phone text
)
returns table (email text)
language sql
security definer
set search_path = public
as $$
  select p.email
  from public.profiles p
  where p.email is not null
    and p.phone = p_phone
    and (
      (p_role = 'user' and p.full_name = p_name and coalesce(p.is_vendor, false) = false)
      or
      (p_role = 'vendor' and exists (
        select 1
        from public.vendors v
        where v.owner_id = p.id
          and v.business_name = p_name
          and v.whatsapp_number = p_phone
      ))
    )
  limit 1;
$$;

revoke all on function public.jalsa_lookup_login(text, text, text) from public;
grant execute on function public.jalsa_lookup_login(text, text, text) to anon, authenticated;
