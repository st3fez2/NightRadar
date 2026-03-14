insert into public.venue_promoters (
  venue_id,
  promoter_id,
  is_active,
  commission_per_guest,
  commission_per_table,
  free_pass_quota,
  reduced_pass_quota
)
values (
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  true,
  0,
  0,
  0,
  0
)
on conflict (venue_id, promoter_id) do update
set is_active = true;

update public.promoters
set
  display_name = coalesce(nullif(trim(display_name), ''), 'Marco Night'),
  bio = coalesce(
    nullif(trim(bio), ''),
    'PR demo NightRadar per liste, accrediti e richieste evento.'
  ),
  public_email = coalesce(
    nullif(trim(public_email), ''),
    'promoter@nightradar.app'
  ),
  instagram_handle = coalesce(
    nullif(trim(instagram_handle), ''),
    'marconight'
  ),
  is_visible = true
where id = '33333333-3333-3333-3333-333333333333';

update public.events
set
  contact_promoter_id = '33333333-3333-3333-3333-333333333333',
  contact_name = null,
  allow_inbox_requests = true,
  allow_email_requests = true,
  allow_whatsapp_requests = false
where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  and venue_id = '22222222-2222-2222-2222-222222222222';

update public.event_offers
set
  promoter_id = '33333333-3333-3333-3333-333333333333',
  is_active = true,
  valid_until = greatest(
    coalesce(valid_until, timezone('utc', now())),
    timezone('utc', now()) + interval '18 hours'
  )
where id = 'cccc1111-cccc-1111-cccc-111111111111'
  and event_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
