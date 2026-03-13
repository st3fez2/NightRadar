alter table public.profiles
  add column if not exists disclaimer_accepted_at timestamptz,
  add column if not exists privacy_accepted_at timestamptz,
  add column if not exists legal_version text;

comment on column public.profiles.disclaimer_accepted_at is
  'Timestamp of disclaimer acceptance for the current legal flow.';

comment on column public.profiles.privacy_accepted_at is
  'Timestamp of privacy policy acceptance for the current legal flow.';

comment on column public.profiles.legal_version is
  'Version label of the accepted legal copy.';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    email,
    phone,
    disclaimer_accepted_at,
    privacy_accepted_at,
    legal_version
  )
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), split_part(coalesce(new.email, 'user'), '@', 1)),
    new.email,
    new.phone,
    nullif(new.raw_user_meta_data ->> 'disclaimer_accepted_at', '')::timestamptz,
    nullif(new.raw_user_meta_data ->> 'privacy_accepted_at', '')::timestamptz,
    nullif(new.raw_user_meta_data ->> 'legal_version', '')
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        email = excluded.email,
        phone = excluded.phone,
        disclaimer_accepted_at = coalesce(public.profiles.disclaimer_accepted_at, excluded.disclaimer_accepted_at),
        privacy_accepted_at = coalesce(public.profiles.privacy_accepted_at, excluded.privacy_accepted_at),
        legal_version = coalesce(public.profiles.legal_version, excluded.legal_version);

  return new;
end;
$$;
