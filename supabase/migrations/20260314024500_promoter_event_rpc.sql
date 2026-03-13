create or replace function public.promoter_create_event(
  p_venue_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_genre text,
  p_description text default null,
  p_minimum_age integer default null,
  p_contact_phone text default null,
  p_contact_email text default null,
  p_venue_delivery_name text default null,
  p_venue_delivery_phone text default null,
  p_venue_delivery_email text default null,
  p_venue_delivery_telegram text default null,
  p_promo_caption text default null,
  p_allow_whatsapp_requests boolean default false,
  p_allow_inbox_requests boolean default true,
  p_allow_email_requests boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_promoter_id uuid;
  v_display_name text;
  v_event_id uuid;
begin
  select p.id, p.display_name
  into v_promoter_id, v_display_name
  from public.promoters p
  where p.profile_id = auth.uid()
  limit 1;

  if v_promoter_id is null then
    raise exception 'Promoter profile not available';
  end if;

  if not public.can_manage_venue(p_venue_id) and not exists (
    select 1
    from public.venue_promoters vp
    where vp.venue_id = p_venue_id
      and vp.promoter_id = v_promoter_id
      and vp.is_active = true
  ) then
    raise exception 'Not allowed to create events for this venue';
  end if;

  insert into public.events (
    venue_id,
    title,
    event_date,
    starts_at,
    ends_at,
    description,
    music_tags,
    status,
    entry_policy,
    is_public,
    minimum_age,
    contact_promoter_id,
    contact_name,
    contact_phone,
    contact_email,
    venue_delivery_name,
    venue_delivery_phone,
    venue_delivery_email,
    venue_delivery_telegram,
    promo_caption,
    allow_whatsapp_requests,
    allow_inbox_requests,
    allow_email_requests,
    created_by
  )
  values (
    p_venue_id,
    p_title,
    timezone('utc', p_starts_at)::date,
    p_starts_at,
    p_starts_at + interval '6 hours',
    coalesce(p_description, 'Evento creato e gestito dal PR su NightRadar.'),
    array[coalesce(nullif(trim(p_genre), ''), 'commerciale')],
    'published',
    'Lista NightRadar e nominativi condivisi con il locale.',
    true,
    p_minimum_age,
    v_promoter_id,
    v_display_name,
    p_contact_phone,
    p_contact_email,
    p_venue_delivery_name,
    p_venue_delivery_phone,
    p_venue_delivery_email,
    p_venue_delivery_telegram,
    p_promo_caption,
    p_allow_whatsapp_requests,
    p_allow_inbox_requests,
    p_allow_email_requests,
    auth.uid()
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;

grant execute on function public.promoter_create_event(
  uuid,
  text,
  timestamptz,
  text,
  text,
  integer,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  boolean,
  boolean
) to authenticated;

create or replace function public.promoter_upsert_event_offer(
  p_offer_id uuid default null,
  p_event_id uuid default null,
  p_title text default null,
  p_type public.offer_type default 'guest_list_reduced',
  p_price numeric default 0,
  p_capacity_total integer default null,
  p_description text default null,
  p_conditions text default null,
  p_valid_until timestamptz default null,
  p_collect_last_name boolean default false,
  p_phone_requirement text default 'lead',
  p_allow_anonymous_entry boolean default false,
  p_requires_list_name boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_promoter_id uuid;
  v_target_event_id uuid;
  v_offer_id uuid;
begin
  select p.id
  into v_promoter_id
  from public.promoters p
  where p.profile_id = auth.uid()
  limit 1;

  if v_promoter_id is null then
    raise exception 'Promoter profile not available';
  end if;

  if p_offer_id is not null then
    select eo.event_id
    into v_target_event_id
    from public.event_offers eo
    where eo.id = p_offer_id;
  else
    v_target_event_id := p_event_id;
  end if;

  if v_target_event_id is null then
    raise exception 'Target event not available';
  end if;

  if not public.can_manage_event(v_target_event_id) and not exists (
    select 1
    from public.events e
    join public.venue_promoters vp
      on vp.venue_id = e.venue_id
     and vp.promoter_id = v_promoter_id
     and vp.is_active = true
    where e.id = v_target_event_id
  ) then
    raise exception 'Not allowed to manage offers for this event';
  end if;

  if p_offer_id is null then
    insert into public.event_offers (
      event_id,
      promoter_id,
      type,
      title,
      description,
      price,
      capacity_total,
      valid_until,
      conditions,
      collect_last_name,
      phone_requirement,
      allow_anonymous_entry,
      requires_list_name,
      created_by,
      is_active
    )
    values (
      v_target_event_id,
      v_promoter_id,
      p_type,
      p_title,
      p_description,
      p_price,
      p_capacity_total,
      p_valid_until,
      p_conditions,
      p_collect_last_name,
      p_phone_requirement,
      p_allow_anonymous_entry,
      p_requires_list_name,
      auth.uid(),
      true
    )
    returning id into v_offer_id;
  else
    update public.event_offers
    set
      title = coalesce(p_title, title),
      type = coalesce(p_type, type),
      price = coalesce(p_price, price),
      capacity_total = p_capacity_total,
      description = p_description,
      conditions = p_conditions,
      valid_until = p_valid_until,
      collect_last_name = p_collect_last_name,
      phone_requirement = p_phone_requirement,
      allow_anonymous_entry = p_allow_anonymous_entry,
      requires_list_name = p_requires_list_name
    where id = p_offer_id
    returning id into v_offer_id;
  end if;

  return v_offer_id;
end;
$$;

grant execute on function public.promoter_upsert_event_offer(
  uuid,
  uuid,
  text,
  public.offer_type,
  numeric,
  integer,
  text,
  text,
  timestamptz,
  boolean,
  text,
  boolean,
  boolean
) to authenticated;

create or replace function public.promoter_archive_event_offer(
  p_offer_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_promoter_id uuid;
begin
  select p.id
  into v_promoter_id
  from public.promoters p
  where p.profile_id = auth.uid()
  limit 1;

  if v_promoter_id is null then
    raise exception 'Promoter profile not available';
  end if;

  if not exists (
    select 1
    from public.event_offers eo
    join public.events e on e.id = eo.event_id
    left join public.venue_promoters vp
      on vp.venue_id = e.venue_id
     and vp.promoter_id = v_promoter_id
     and vp.is_active = true
    where eo.id = p_offer_id
      and (vp.id is not null or public.can_manage_event(e.id))
  ) then
    raise exception 'Not allowed to archive this offer';
  end if;

  update public.event_offers
  set is_active = false
  where id = p_offer_id;
end;
$$;

grant execute on function public.promoter_archive_event_offer(uuid) to authenticated;
