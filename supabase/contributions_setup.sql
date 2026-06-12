-- ============================================================================
-- Setup des contributions ("Ajouter une adresse" + "Donner mon avis")
--
-- A EXECUTER UNE FOIS dans le dashboard Supabase :
--   Dashboard -> SQL Editor -> New query -> coller ce fichier -> Run
--
-- Ou retrouver les soumissions ensuite :
--   Dashboard -> Table Editor -> address_submissions / review_submissions
--   (les nouvelles arrivent avec status = 'pending' ; passez-les a 'approved'
--    ou 'rejected' apres verification)
--   Les photos sont dans Storage -> bucket "contributions"
--     (dossiers addresses/ et reviews/)
-- ============================================================================

-- ---- 1. Table des adresses proposees ---------------------------------------
create table if not exists public.address_submissions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  status text not null default 'pending',  -- pending | approved | rejected
  name text not null,
  address text not null,
  description text not null,
  type text,
  website text,
  instagram text,
  submitter_email text,
  photo_urls jsonb not null default '[]'::jsonb
);

-- ---- 2. Table des avis soumis ----------------------------------------------
create table if not exists public.review_submissions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  status text not null default 'pending',  -- pending | approved | rejected
  place_id text,                            -- null si nouveau lieu propose
  place_name text not null,
  is_new_place boolean not null default false,
  new_place_address text,
  rating int not null check (rating between 1 and 5),
  comment text not null,
  submitter_name text,
  submitter_email text,
  photo_urls jsonb not null default '[]'::jsonb
);

-- ---- 3. Securite (RLS) : l'app peut UNIQUEMENT inserer ----------------------
-- Personne ne peut lire/modifier/supprimer depuis l'app (cle anon) :
-- les soumissions ne sont visibles que depuis le dashboard.
alter table public.address_submissions enable row level security;
alter table public.review_submissions enable row level security;

drop policy if exists "anon insert address_submissions" on public.address_submissions;
create policy "anon insert address_submissions"
  on public.address_submissions for insert
  to anon with check (true);

drop policy if exists "anon insert review_submissions" on public.review_submissions;
create policy "anon insert review_submissions"
  on public.review_submissions for insert
  to anon with check (true);

-- ---- 4. Bucket Storage pour les photos --------------------------------------
insert into storage.buckets (id, name, public)
values ('contributions', 'contributions', true)
on conflict (id) do nothing;

-- L'app peut uploader des photos dans ce bucket (mais pas lister/supprimer).
drop policy if exists "anon upload contributions" on storage.objects;
create policy "anon upload contributions"
  on storage.objects for insert
  to anon with check (bucket_id = 'contributions');
