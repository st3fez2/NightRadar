create or replace function public.generate_unique_venue_slug(
  p_base text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seed text := lower(
    regexp_replace(coalesce(p_base, 'venue'), '[^a-zA-Z0-9]+', '-', 'g')
  );
  v_slug text;
begin
  v_seed := trim(both '-' from v_seed);

  if v_seed = '' then
    v_seed := 'venue';
  end if;

  v_slug := v_seed;

  while exists (
    select 1
    from public.venues
    where slug = v_slug
  ) loop
    v_slug := v_seed || '-' || lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
  end loop;

  return v_slug;
end;
$$;

create or replace function public.promoter_create_event_v2(
  p_venue_name text,
  p_city text,
  p_address_line text default null,
  p_title text default null,
  p_starts_at timestamptz default null,
  p_genre text default null,
  p_description text default null,
  p_cover_image_url text default null,
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
  v_venue_id uuid;
  v_clean_venue_name text := nullif(trim(coalesce(p_venue_name, '')), '');
  v_clean_city text := nullif(trim(coalesce(p_city, '')), '');
  v_clean_address text := nullif(trim(coalesce(p_address_line, '')), '');
begin
  select p.id, p.display_name
  into v_promoter_id, v_display_name
  from public.promoters p
  where p.profile_id = auth.uid()
    and coalesce(p.is_suspended, false) = false
  limit 1;

  if v_promoter_id is null then
    raise exception 'Promoter profile not available';
  end if;

  if v_clean_venue_name is null then
    raise exception 'Venue name is required';
  end if;

  if v_clean_city is null then
    raise exception 'City is required';
  end if;

  if nullif(trim(coalesce(p_title, '')), '') is null then
    raise exception 'Event title is required';
  end if;

  if p_starts_at is null then
    raise exception 'Event start is required';
  end if;

  select v.id
  into v_venue_id
  from public.venues v
  where lower(trim(v.name)) = lower(v_clean_venue_name)
    and lower(trim(v.city)) = lower(v_clean_city)
    and (
      v_clean_address is null
      or lower(trim(v.address_line)) = lower(v_clean_address)
    )
  order by v.created_at
  limit 1;

  if v_venue_id is null then
    insert into public.venues (
      name,
      slug,
      description,
      address_line,
      city,
      capacity,
      categories,
      dress_code,
      price_band,
      created_by
    )
    values (
      v_clean_venue_name,
      public.generate_unique_venue_slug(v_clean_venue_name || '-' || v_clean_city),
      'Locale inserito direttamente dal PR su NightRadar.',
      coalesce(v_clean_address, v_clean_venue_name),
      v_clean_city,
      0,
      '{}'::text[],
      null,
      null,
      auth.uid()
    )
    returning id into v_venue_id;
  end if;

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
    v_venue_id,
    v_promoter_id,
    true,
    0,
    0,
    0,
    0
  )
  on conflict (venue_id, promoter_id) do update
  set is_active = true,
      updated_at = timezone('utc', now());

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
    cover_image_url,
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
    v_venue_id,
    trim(p_title),
    timezone('utc', p_starts_at)::date,
    p_starts_at,
    p_starts_at + interval '6 hours',
    coalesce(p_description, 'Evento creato e gestito dal PR su NightRadar.'),
    array[coalesce(nullif(trim(p_genre), ''), 'commerciale')],
    'published',
    'Lista NightRadar e nominativi condivisi con il locale.',
    true,
    p_minimum_age,
    nullif(trim(coalesce(p_cover_image_url, '')), ''),
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

grant execute on function public.promoter_create_event_v2(
  text,
  text,
  text,
  text,
  timestamptz,
  text,
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
  v_venue public.venues%rowtype;
begin
  select *
  into v_venue
  from public.venues
  where id = p_venue_id;

  if v_venue.id is null then
    raise exception 'Target venue not available';
  end if;

  return public.promoter_create_event_v2(
    p_venue_name => v_venue.name,
    p_city => v_venue.city,
    p_address_line => v_venue.address_line,
    p_title => p_title,
    p_starts_at => p_starts_at,
    p_genre => p_genre,
    p_description => p_description,
    p_cover_image_url => null,
    p_minimum_age => p_minimum_age,
    p_contact_phone => p_contact_phone,
    p_contact_email => p_contact_email,
    p_venue_delivery_name => p_venue_delivery_name,
    p_venue_delivery_phone => p_venue_delivery_phone,
    p_venue_delivery_email => p_venue_delivery_email,
    p_venue_delivery_telegram => p_venue_delivery_telegram,
    p_promo_caption => p_promo_caption,
    p_allow_whatsapp_requests => p_allow_whatsapp_requests,
    p_allow_inbox_requests => p_allow_inbox_requests,
    p_allow_email_requests => p_allow_email_requests
  );
end;
$$;
