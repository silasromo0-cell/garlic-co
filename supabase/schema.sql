-- Garlic & Co: run this whole file once in Supabase → SQL Editor, THEN run seed.sql.

create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('platters','buildFeature','extras','assemble','snoek','sides')),
  name text not null,
  description text,
  sub text,
  price integer not null check (price >= 0),
  image_url text,
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_ref text not null,
  customer_name text not null check (char_length(customer_name) <= 120),
  phone text not null check (char_length(phone) <= 40),
  fulfillment text not null check (fulfillment in ('pickup','delivery','dinein')),
  address text check (char_length(address) <= 500),
  notes text check (char_length(notes) <= 1000),
  items jsonb not null,
  total integer not null check (total >= 0),
  status text not null default 'new' check (status in ('new','paid','done','cancelled')),
  created_at timestamptz not null default now()
);

-- Who counts as admin (must also exist under Authentication → Users)
create table public.admins (email text primary key);
insert into public.admins values ('YOUR_EMAIL@example.com');   -- ← change this

create function public.is_admin() returns boolean
language sql security definer set search_path = public stable as
$$ select exists (select 1 from public.admins where email = (auth.jwt() ->> 'email')) $$;
grant execute on function public.is_admin() to anon, authenticated;

alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.admins enable row level security;   -- no policies = nobody can read it directly

create policy "public reads available menu" on public.menu_items for select using (is_available or public.is_admin());
create policy "admin manages menu" on public.menu_items for all using (public.is_admin()) with check (public.is_admin());

create policy "anyone can place an order" on public.orders for insert to anon, authenticated with check (status = 'new');
create policy "admin reads orders" on public.orders for select using (public.is_admin());
create policy "admin updates orders" on public.orders for update using (public.is_admin());
create policy "admin deletes orders" on public.orders for delete using (public.is_admin());

-- Photos bucket (public to view, admin-only to change)
insert into storage.buckets (id, name, public) values ('menu-images','menu-images',true) on conflict do nothing;
create policy "admin uploads photos" on storage.objects for insert with check (bucket_id = 'menu-images' and public.is_admin());
create policy "admin edits photos" on storage.objects for update using (bucket_id = 'menu-images' and public.is_admin());
create policy "admin deletes photos" on storage.objects for delete using (bucket_id = 'menu-images' and public.is_admin());
