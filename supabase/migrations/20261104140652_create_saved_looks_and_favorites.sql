-- Run once in Supabase Dashboard -> SQL Editor.
-- A new empty table is deliberate: sample/mock items are not migrated.

create table if not exists public.saved_looks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  occasion text not null,
  description text not null default '',
  preview_color bigint not null,
  preview_icon text not null default 'sparkle',
  created_at timestamptz not null default now(),
  unique (user_id, title, occasion)
);

create table if not exists public.favorite_products (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_key text not null,
  product_data jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, product_key)
);

create index if not exists saved_looks_owner_created_idx
  on public.saved_looks (user_id, created_at desc);
create index if not exists favorite_products_owner_created_idx
  on public.favorite_products (user_id, created_at desc);

alter table public.saved_looks enable row level security;
alter table public.favorite_products enable row level security;

-- Needed when 'Automatically expose new tables' was disabled.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.saved_looks to authenticated;
grant select, insert, update, delete on public.favorite_products to authenticated;

create policy "saved looks select own" on public.saved_looks
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "saved looks insert own" on public.saved_looks
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "saved looks update own" on public.saved_looks
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "saved looks delete own" on public.saved_looks
  for delete to authenticated using ((select auth.uid()) = user_id);

create policy "favorites select own" on public.favorite_products
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "favorites insert own" on public.favorite_products
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "favorites update own" on public.favorite_products
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "favorites delete own" on public.favorite_products
  for delete to authenticated using ((select auth.uid()) = user_id);
