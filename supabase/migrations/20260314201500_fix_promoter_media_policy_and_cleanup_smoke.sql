drop policy if exists "promoter media read own"
on storage.objects;

drop policy if exists "promoter media upload own"
on storage.objects;

drop policy if exists "promoter media update own"
on storage.objects;

drop policy if exists "promoter media delete own"
on storage.objects;

create policy "promoter media read own"
on storage.objects for select to authenticated
using (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);

create policy "promoter media upload own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);

create policy "promoter media update own"
on storage.objects for update to authenticated
using (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
)
with check (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);

create policy "promoter media delete own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'promoter-media'
  and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
);

delete from public.event_offers
where id = '44f5cfa6-78f9-45ca-a110-20dc4224eb6b'
  and event_id = 'ae9fb9ce-b259-4b57-85dd-b8c3a7f61264';

delete from public.events
where id = 'ae9fb9ce-b259-4b57-85dd-b8c3a7f61264'
  and title = 'Smoke test PR dashboard'
  and created_by = 'c258afac-e0f3-4a06-a772-e8952ad3852f';

update public.promoters
set
  bio = 'PR demo NightRadar per liste, accrediti e richieste evento.',
  avatar_url = null
where id = '33333333-3333-3333-3333-333333333333'
  and bio = 'Smoke profile update'
  and avatar_url = 'https://st3fez2.github.io/NightRadar/assets/assets/branding/nightradar_mark.png';
