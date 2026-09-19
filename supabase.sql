-- Florida Fort Lauderdale Mission — Supabase database setup
-- In Supabase: SQL Editor -> New query -> paste this file -> Run.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id,email) values (new.id,new.email)
  on conflict (id) do update set email=excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.companionships (
  id uuid primary key default gen_random_uuid(),
  missionaries text not null,
  notes text,
  pdf_path text,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.areas (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  display_order integer not null default 0,
  boundary_geojson jsonb,
  companionship_id uuid references public.companionships(id) on delete set null,
  owner_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.cars (
  id uuid primary key default gen_random_uuid(), year text, make text, model text, vin text, plate text,
  gas_card text, area_id uuid references public.areas(id) on delete set null,
  companionship_id uuid references public.companionships(id) on delete set null,
  owner_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now()
);

create table if not exists public.houses (
  id uuid primary key default gen_random_uuid(), house_name text, address text, capacity text,
  total_keys text, keys_in_field text, area_id uuid references public.areas(id) on delete set null,
  companionship_id uuid references public.companionships(id) on delete set null,
  owner_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now()
);

create table if not exists public.phone_numbers (
  id uuid primary key default gen_random_uuid(), location text, phone text, notes text,
  area_id uuid references public.areas(id) on delete set null,
  companionship_id uuid references public.companionships(id) on delete set null,
  owner_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.areas enable row level security;
alter table public.companionships enable row level security;
alter table public.cars enable row level security;
alter table public.houses enable row level security;
alter table public.phone_numbers enable row level security;

create policy "profiles own row" on public.profiles for select to authenticated using (auth.uid()=id);
create policy "profiles update own row" on public.profiles for update to authenticated using (auth.uid()=id);

create policy "areas read" on public.areas for select to authenticated using (true);
create policy "areas insert own" on public.areas for insert to authenticated with check (auth.uid()=owner_id);
create policy "areas update own" on public.areas for update to authenticated using (auth.uid()=owner_id) with check (auth.uid()=owner_id);
create policy "areas delete own" on public.areas for delete to authenticated using (auth.uid()=owner_id);

create policy "companionships read" on public.companionships for select to authenticated using (true);
create policy "companionships insert own" on public.companionships for insert to authenticated with check (auth.uid()=owner_id);
create policy "companionships update own" on public.companionships for update to authenticated using (auth.uid()=owner_id) with check (auth.uid()=owner_id);
create policy "companionships delete own" on public.companionships for delete to authenticated using (auth.uid()=owner_id);

create policy "cars read" on public.cars for select to authenticated using (true);
create policy "cars insert own" on public.cars for insert to authenticated with check (auth.uid()=owner_id);
create policy "cars update own" on public.cars for update to authenticated using (auth.uid()=owner_id) with check (auth.uid()=owner_id);
create policy "cars delete own" on public.cars for delete to authenticated using (auth.uid()=owner_id);

create policy "houses read" on public.houses for select to authenticated using (true);
create policy "houses insert own" on public.houses for insert to authenticated with check (auth.uid()=owner_id);
create policy "houses update own" on public.houses for update to authenticated using (auth.uid()=owner_id) with check (auth.uid()=owner_id);
create policy "houses delete own" on public.houses for delete to authenticated using (auth.uid()=owner_id);

create policy "phones read" on public.phone_numbers for select to authenticated using (true);
create policy "phones insert own" on public.phone_numbers for insert to authenticated with check (auth.uid()=owner_id);
create policy "phones update own" on public.phone_numbers for update to authenticated using (auth.uid()=owner_id) with check (auth.uid()=owner_id);
create policy "phones delete own" on public.phone_numbers for delete to authenticated using (auth.uid()=owner_id);

insert into storage.buckets (id,name,public) values ('assignment-pdfs','assignment-pdfs',false)
on conflict (id) do nothing;

create policy "assignment pdf read" on storage.objects for select to authenticated using (bucket_id='assignment-pdfs');
create policy "assignment pdf upload" on storage.objects for insert to authenticated
with check (bucket_id='assignment-pdfs' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "assignment pdf update own" on storage.objects for update to authenticated
using (bucket_id='assignment-pdfs' and (storage.foldername(name))[1]=auth.uid()::text)
with check (bucket_id='assignment-pdfs' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "assignment pdf delete own" on storage.objects for delete to authenticated
using (bucket_id='assignment-pdfs' and (storage.foldername(name))[1]=auth.uid()::text);
