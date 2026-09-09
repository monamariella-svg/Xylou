create extension if not exists pgcrypto;
create schema if not exists auth;
create schema if not exists extensions;
do $$ begin
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
  if not exists (select 1 from pg_roles where rolname='supabase_admin') then create role supabase_admin nologin; end if;
end $$;
create table if not exists auth.users (id uuid primary key default gen_random_uuid(), email text);
create or replace function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create or replace function auth.jwt() returns jsonb language sql stable as $$ select '{}'::jsonb $$;
create or replace function auth.role() returns text language sql stable as $$ select 'authenticated'::text $$;
create schema if not exists storage;
create or replace function storage.foldername(name text) returns text[]
  language plpgsql immutable as $fn$
declare a text[]; begin a := string_to_array(name, '/'); return a[1:array_length(a,1)-1]; end $fn$;
create table if not exists storage.buckets (id text primary key, name text, public boolean default false);
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets,
  name text, owner uuid, created_at timestamptz default now(), metadata jsonb);
alter table storage.objects enable row level security;
create schema if not exists net;
create schema if not exists vault;
create table if not exists vault.decrypted_secrets (id uuid default gen_random_uuid(), name text, decrypted_secret text);
create or replace function net.http_post(url text, body jsonb default '{}', params jsonb default '{}', headers jsonb default '{}', timeout_milliseconds int default 5000)
  returns bigint language sql as $$ select 1::bigint $$;
create schema if not exists cron;
create or replace function cron.schedule(job_name text, schedule text, command text) returns bigint language sql as $$ select 1::bigint $$;
