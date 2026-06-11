-- ============================================================
-- ParisMap : schéma Supabase
-- Coller dans l'éditeur SQL de ton projet Supabase et exécuter.
-- ============================================================

-- 1. Table principale des lieux
create table if not exists public.places (
  id            text primary key,
  name          text not null,
  type          text not null
                  check (type in ('bar','restaurant','hotel','rooftop','parc','adresse')),
  latitude      float8 not null,
  longitude     float8 not null,
  address       text not null,
  rating        float8 not null default 4.0
                  check (rating between 0 and 5),
  review_count  int4  not null default 0,
  price_level   int4  not null default 1
                  check (price_level between 1 and 4),
  ambiance_tags text[] not null default '{}',
  music_tags    text[] not null default '{}',
  style_tags    text[] not null default '{}',
  is_premium    bool  not null default false,
  website_url   text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2. Trigger : updated_at automatique
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_places_updated_at on public.places;
create trigger trg_places_updated_at
  before update on public.places
  for each row execute procedure public.set_updated_at();

-- 2b. Nouvelles colonnes pour filtres avancés
--     (exécuter séparément si la table existe déjà)
alter table public.places
  add column if not exists average_price_per_person int4 not null default 0,
  add column if not exists opening_hours text[] not null default '{}',
  add column if not exists cuisine_tags   text[] not null default '{}';

-- 3. Row Level Security
alter table public.places enable row level security;

-- Lecture publique (l'app lit sans authentification)
drop policy if exists "Lecture publique" on public.places;
create policy "Lecture publique" on public.places
  for select using (true);

-- Les écritures passent par le dashboard Supabase (service_role bypass RLS).
-- Si tu veux autoriser des insertions depuis l'app avec un compte admin :
-- create policy "Ecriture admin" on public.places
--   for all using (auth.role() = 'authenticated');
