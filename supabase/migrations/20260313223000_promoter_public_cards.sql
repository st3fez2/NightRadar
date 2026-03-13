alter table public.promoters
  add column if not exists avatar_url text,
  add column if not exists public_phone text,
  add column if not exists public_email text;

update public.promoters p
set
  avatar_url = coalesce(
    p.avatar_url,
    (
      select pr.avatar_url
      from public.profiles pr
      where pr.id = p.profile_id
      limit 1
    )
  ),
  public_phone = coalesce(
    nullif(trim(p.public_phone), ''),
    (
      select pr.phone
      from public.profiles pr
      where pr.id = p.profile_id
      limit 1
    )
  ),
  public_email = coalesce(
    nullif(trim(p.public_email), ''),
    (
      select pr.email
      from public.profiles pr
      where pr.id = p.profile_id
      limit 1
    )
  );

create policy "promoters public readable by anon"
on public.promoters for select to anon
using (
  is_visible = true
  and exists (
    select 1
    from public.event_offers eo
    join public.events e on e.id = eo.event_id
    where eo.promoter_id = promoters.id
      and eo.is_active = true
      and e.is_public = true
      and e.status in ('published', 'live')
  )
);
