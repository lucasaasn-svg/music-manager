-- MUSIC MANAGER V5 — SUPABASE SETUP
-- Execute este arquivo inteiro no SQL Editor do seu projeto Supabase.
-- Depois crie sua conta no site e execute o último UPDATE para virar administrador.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text not null,
  album text,
  audio_url text not null,
  storage_path text not null,
  cover_url text,
  cover_path text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.likes (
  user_id uuid not null references auth.users(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, song_id)
);

alter table public.profiles enable row level security;
alter table public.songs enable row level security;
alter table public.likes enable row level security;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Profiles: each logged-in user can read only their own profile.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
for select to authenticated
using (id = auth.uid());

-- Songs: everyone can read the catalog.
drop policy if exists "songs_public_read" on public.songs;
create policy "songs_public_read" on public.songs
for select to anon, authenticated
using (true);

-- Songs: only admins can insert/update/delete.
drop policy if exists "songs_admin_insert" on public.songs;
create policy "songs_admin_insert" on public.songs
for insert to authenticated
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));

drop policy if exists "songs_admin_update" on public.songs;
create policy "songs_admin_update" on public.songs
for update to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));

drop policy if exists "songs_admin_delete" on public.songs;
create policy "songs_admin_delete" on public.songs
for delete to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));

-- Likes: users can manage their own likes.
drop policy if exists "likes_select_own" on public.likes;
create policy "likes_select_own" on public.likes
for select to authenticated using (user_id = auth.uid());

drop policy if exists "likes_insert_own" on public.likes;
create policy "likes_insert_own" on public.likes
for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "likes_delete_own" on public.likes;
create policy "likes_delete_own" on public.likes
for delete to authenticated using (user_id = auth.uid());

-- Storage buckets.
insert into storage.buckets (id, name, public)
values ('music','music',true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('covers','covers',true)
on conflict (id) do update set public = true;

-- Storage: anyone can read public files.
drop policy if exists "public_read_music" on storage.objects;
create policy "public_read_music" on storage.objects
for select to anon, authenticated
using (bucket_id = 'music');

drop policy if exists "public_read_covers" on storage.objects;
create policy "public_read_covers" on storage.objects
for select to anon, authenticated
using (bucket_id = 'covers');

-- Storage: only admins can upload/delete.
drop policy if exists "admin_insert_music" on storage.objects;
create policy "admin_insert_music" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'music'
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true)
);

drop policy if exists "admin_delete_music" on storage.objects;
create policy "admin_delete_music" on storage.objects
for delete to authenticated
using (
  bucket_id = 'music'
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true)
);

drop policy if exists "admin_insert_covers" on storage.objects;
create policy "admin_insert_covers" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'covers'
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true)
);

drop policy if exists "admin_delete_covers" on storage.objects;
create policy "admin_delete_covers" on storage.objects
for delete to authenticated
using (
  bucket_id = 'covers'
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true)
);

-- Depois de criar sua conta no Music Manager:
-- 1) descubra o UUID do usuário em Authentication > Users.
-- 2) substitua SEU_UUID_AQUI e execute:
--
-- update public.profiles
-- set is_admin = true
-- where id = 'SEU_UUID_AQUI';
--
-- IMPORTANTE: não coloque a service_role key no index.html.
