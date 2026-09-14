-- Music Manager V5 — Supabase setup
-- Execute este arquivo inteiro no SQL Editor do seu projeto.
-- Não coloque service_role/secret key no site.

create extension if not exists pgcrypto;

-- Perfil do usuário
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- Catálogo
create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text not null,
  album text,
  audio_url text not null,
  storage_path text not null,
  cover_url text,
  cover_path text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Curtidas
create table if not exists public.likes (
  user_id uuid not null references auth.users(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, song_id)
);

-- Função segura para checar administrador sem depender de uma policy
-- recursiva na tabela profiles.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and is_admin = true
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- Cria o perfil automaticamente quando uma conta é criada.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;
alter table public.songs enable row level security;
alter table public.likes enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_admin_select" on public.profiles;
create policy "profiles_admin_select"
on public.profiles for select
to authenticated
using (public.is_admin());

drop policy if exists "profiles_admin_update" on public.profiles;
create policy "profiles_admin_update"
on public.profiles for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Catálogo: leitura pública para o site.
drop policy if exists "songs_public_read" on public.songs;
create policy "songs_public_read"
on public.songs for select
to anon, authenticated
using (true);

drop policy if exists "songs_admin_insert" on public.songs;
create policy "songs_admin_insert"
on public.songs for insert
to authenticated
with check (public.is_admin());

drop policy if exists "songs_admin_update" on public.songs;
create policy "songs_admin_update"
on public.songs for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "songs_admin_delete" on public.songs;
create policy "songs_admin_delete"
on public.songs for delete
to authenticated
using (public.is_admin());

-- Curtidas: cada usuário só manipula as próprias.
drop policy if exists "likes_select_own" on public.likes;
create policy "likes_select_own"
on public.likes for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "likes_insert_own" on public.likes;
create policy "likes_insert_own"
on public.likes for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "likes_delete_own" on public.likes;
create policy "likes_delete_own"
on public.likes for delete
to authenticated
using (user_id = auth.uid());

-- Storage: buckets públicos para que o player consiga tocar as músicas
-- e mostrar as capas sem exigir URL assinada.
insert into storage.buckets (id, name, public)
values ('music', 'music', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do update set public = true;

-- Leitura pública dos arquivos.
drop policy if exists "music_public_read" on storage.objects;
create policy "music_public_read"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'music');

drop policy if exists "covers_public_read" on storage.objects;
create policy "covers_public_read"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'covers');

-- Somente administrador pode enviar/alterar/excluir arquivos.
drop policy if exists "music_admin_insert" on storage.objects;
create policy "music_admin_insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'music' and public.is_admin());

drop policy if exists "music_admin_update" on storage.objects;
create policy "music_admin_update"
on storage.objects for update
to authenticated
using (bucket_id = 'music' and public.is_admin())
with check (bucket_id = 'music' and public.is_admin());

drop policy if exists "music_admin_delete" on storage.objects;
create policy "music_admin_delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'music' and public.is_admin());

drop policy if exists "covers_admin_insert" on storage.objects;
create policy "covers_admin_insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'covers' and public.is_admin());

drop policy if exists "covers_admin_update" on storage.objects;
create policy "covers_admin_update"
on storage.objects for update
to authenticated
using (bucket_id = 'covers' and public.is_admin())
with check (bucket_id = 'covers' and public.is_admin());

drop policy if exists "covers_admin_delete" on storage.objects;
create policy "covers_admin_delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'covers' and public.is_admin());

-- Depois de criar sua conta no site, rode:
-- update public.profiles set is_admin = true where id = 'SEU_UUID';
