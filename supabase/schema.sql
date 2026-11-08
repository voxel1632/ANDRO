-- Run this once in Supabase SQL Editor. The publishable key is safe for browser use only with these RLS rules enabled.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Creator',
  role text not null default 'creator' check (role in ('creator','admin')),
  is_disabled boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'display_name','Creator')) on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create table if not exists public.mods (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text not null,
  category text not null,
  version text not null default '1.0.0',
  author text not null,
  tags text[] not null default '{}',
  icon_url text,
  banner_url text,
  screenshot_urls text[] not null default '{}',
  file_url text not null,
  file_path text not null,
  icon_path text,
  banner_path text,
  screenshot_paths text[] not null default '{}',
  download_count bigint not null default 0 check (download_count >= 0),
  featured boolean not null default false,
  trending boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Apply missing columns when the existing mods table predates this app.
alter table public.mods add column if not exists owner_id uuid references auth.users(id) on delete cascade;
alter table public.mods add column if not exists name text;
alter table public.mods add column if not exists description text;
alter table public.mods add column if not exists category text;
alter table public.mods add column if not exists version text not null default '1.0.0';
alter table public.mods add column if not exists author text;
alter table public.mods add column if not exists tags text[] not null default '{}';
alter table public.mods add column if not exists icon_url text;
alter table public.mods add column if not exists banner_url text;
alter table public.mods add column if not exists screenshot_urls text[] not null default '{}';
alter table public.mods add column if not exists file_url text;
alter table public.mods add column if not exists file_path text;
alter table public.mods add column if not exists icon_path text;
alter table public.mods add column if not exists banner_path text;
alter table public.mods add column if not exists screenshot_paths text[] not null default '{}';
alter table public.mods add column if not exists download_count bigint not null default 0;
alter table public.mods add column if not exists featured boolean not null default false;
alter table public.mods add column if not exists trending boolean not null default false;
alter table public.mods add column if not exists created_at timestamptz not null default now();
alter table public.mods add column if not exists updated_at timestamptz not null default now();
create index if not exists mods_owner_id_idx on public.mods(owner_id);
create index if not exists mods_created_at_idx on public.mods(created_at desc);
create index if not exists mods_category_idx on public.mods(category);
create index if not exists mods_tags_idx on public.mods using gin(tags);

create or replace function public.touch_updated_at() returns trigger language plpgsql set search_path = '' as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists mods_touch_updated_at on public.mods;
create trigger mods_touch_updated_at before update on public.mods for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.mods enable row level security;
drop policy if exists "profiles public read" on public.profiles;
create policy "profiles public read" on public.profiles for select using (true);
drop policy if exists "profile owner update" on public.profiles;
create policy "profile owner update" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id and role=(select p.role from public.profiles p where p.id=auth.uid()));
drop policy if exists "mods public read" on public.mods;
create policy "mods public read" on public.mods for select using (true);
drop policy if exists "creator inserts own mods" on public.mods;
create policy "creator inserts own mods" on public.mods for insert to authenticated with check (owner_id=auth.uid() and exists(select 1 from public.profiles p where p.id=auth.uid() and not p.is_disabled));
drop policy if exists "owner or admin updates mods" on public.mods;
create policy "owner or admin updates mods" on public.mods for update to authenticated using (owner_id=auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')) with check (owner_id=auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "owner or admin deletes mods" on public.mods;
create policy "owner or admin deletes mods" on public.mods for delete to authenticated using (owner_id=auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values ('mods','mods',true,104857600,array['application/zip','application/octet-stream','application/x-zip-compressed','image/png','image/jpeg','image/webp','image/gif']) on conflict(id) do update set public=true,file_size_limit=104857600;
drop policy if exists "public read mod assets" on storage.objects;
create policy "public read mod assets" on storage.objects for select using (bucket_id='mods');
drop policy if exists "creator upload own assets" on storage.objects;
create policy "creator upload own assets" on storage.objects for insert to authenticated with check (bucket_id='mods' and (storage.foldername(name))[1]=auth.uid()::text and exists(select 1 from public.profiles p where p.id=auth.uid() and not p.is_disabled));
drop policy if exists "creator or admin remove assets" on storage.objects;
create policy "creator or admin remove assets" on storage.objects for delete to authenticated using (bucket_id='mods' and ((storage.foldername(name))[1]=auth.uid()::text or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')));
drop policy if exists "creator or admin update assets" on storage.objects;
create policy "creator or admin update assets" on storage.objects for update to authenticated using (bucket_id='mods' and ((storage.foldername(name))[1]=auth.uid()::text or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')));

create or replace function public.increment_mod_downloads(mod_id uuid) returns bigint
language plpgsql security definer set search_path = '' as $$ declare new_count bigint; begin update public.mods set download_count=download_count+1 where id=mod_id returning download_count into new_count; if new_count is null then raise exception 'Mod not found'; end if; return new_count; end; $$;
revoke all on function public.increment_mod_downloads(uuid) from public;
grant execute on function public.increment_mod_downloads(uuid) to anon, authenticated;

create or replace function public.delete_mod_and_files(mod_id uuid) returns void
language plpgsql security invoker set search_path = '' as $$ begin delete from public.mods where id=mod_id; if not found then raise exception 'Mod not found or permission denied'; end if; end; $$;
revoke all on function public.delete_mod_and_files(uuid) from public;
grant execute on function public.delete_mod_and_files(uuid) to authenticated;

create or replace function public.admin_remove_creator(creator_email text) returns text
language plpgsql security definer set search_path = '' as $$ declare target uuid; begin if not exists(select 1 from public.profiles where id=auth.uid() and role='admin') then raise exception 'Admin access required'; end if; select id into target from auth.users where email=creator_email; if target is null then raise exception 'Creator not found'; end if; if target=auth.uid() then raise exception 'You cannot disable your own admin account'; end if; update public.profiles set is_disabled=true where id=target; return 'Creator account disabled.'; end; $$;
revoke all on function public.admin_remove_creator(text) from public;
grant execute on function public.admin_remove_creator(text) to authenticated;

-- After signing up with the account you intend to administer, run this with its email in place of admin@example.com.
-- Never put an admin password in client-side source. Use Supabase Auth to manage the password.
-- update public.profiles set role='admin' where id=(select id from auth.users where email='admin@example.com');
