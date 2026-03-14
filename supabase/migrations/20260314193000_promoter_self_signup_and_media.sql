create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_requested_role public.app_role := case
    when lower(coalesce(new.raw_user_meta_data ->> 'requested_role', '')) = 'promoter'
      then 'promoter'::public.app_role
    else 'user'::public.app_role
  end;
begin
  insert into public.profiles (
    id,
    full_name,
    email,
    phone,
    role,
    disclaimer_accepted_at,
    privacy_accepted_at,
    legal_version
  )
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, 'user'), '@', 1)
    ),
    new.email,
    new.phone,
    v_requested_role,
    nullif(new.raw_user_meta_data ->> 'disclaimer_accepted_at', '')::timestamptz,
    nullif(new.raw_user_meta_data ->> 'privacy_accepted_at', '')::timestamptz,
    nullif(new.raw_user_meta_data ->> 'legal_version', '')
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        email = excluded.email,
        phone = excluded.phone,
        role = case
          when excluded.role = 'promoter'::public.app_role
            then 'promoter'::public.app_role
          else public.profiles.role
        end,
        disclaimer_accepted_at = coalesce(
          public.profiles.disclaimer_accepted_at,
          excluded.disclaimer_accepted_at
        ),
        privacy_accepted_at = coalesce(
          public.profiles.privacy_accepted_at,
          excluded.privacy_accepted_at
        ),
        legal_version = coalesce(
          public.profiles.legal_version,
          excluded.legal_version
        );

  perform public.sync_approved_promoter_request_for_profile(new.id);

  if v_requested_role = 'promoter'::public.app_role then
    update public.profiles
    set role = 'promoter'
    where id = new.id
      and role is distinct from 'promoter';
  end if;

  return new;
end;
$$;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'promoter-media',
  'promoter-media',
  true,
  5242880,
  array['image/png', 'image/jpeg', 'image/webp', 'image/gif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "promoter media upload own"
on storage.objects;

create policy "promoter media upload own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "promoter media update own"
on storage.objects;

create policy "promoter media update own"
on storage.objects for update to authenticated
using (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "promoter media delete own"
on storage.objects;

create policy "promoter media delete own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);
