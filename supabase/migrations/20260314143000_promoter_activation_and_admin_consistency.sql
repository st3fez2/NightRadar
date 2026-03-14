create or replace function public.generate_unique_promoter_referral_code(
  p_base text default 'PR'
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seed text := upper(regexp_replace(coalesce(p_base, 'PR'), '[^A-Za-z0-9]+', '', 'g'));
  v_prefix text;
  v_candidate text;
begin
  v_prefix := left(coalesce(nullif(v_seed, ''), 'PR'), 6);

  loop
    v_candidate := v_prefix || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    exit when not exists (
      select 1
      from public.promoters
      where referral_code = v_candidate
    );
  end loop;

  return v_candidate;
end;
$$;

create or replace function public.is_active_venue_promoter(
  p_venue_id uuid,
  p_promoter_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.venue_promoters vp
    where vp.venue_id = p_venue_id
      and vp.promoter_id = p_promoter_id
      and vp.is_active = true
  );
$$;

create or replace function public.ensure_promoter_profile_row(
  p_profile_id uuid,
  p_display_name text default null,
  p_instagram_handle text default null,
  p_mark_verified boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles%rowtype;
  v_promoter_id uuid;
  v_display_name text;
  v_instagram_handle text;
begin
  select *
  into v_profile
  from public.profiles
  where id = p_profile_id;

  if v_profile.id is null then
    raise exception 'Profile not found for promoter sync';
  end if;

  v_display_name := coalesce(
    nullif(trim(p_display_name), ''),
    nullif(trim(v_profile.full_name), ''),
    'PR'
  );
  v_instagram_handle := nullif(trim(coalesce(p_instagram_handle, '')), '');

  select id
  into v_promoter_id
  from public.promoters
  where profile_id = p_profile_id
  limit 1;

  if v_promoter_id is null then
    insert into public.promoters (
      profile_id,
      display_name,
      instagram_handle,
      referral_code,
      is_verified
    )
    values (
      p_profile_id,
      v_display_name,
      v_instagram_handle,
      public.generate_unique_promoter_referral_code(v_display_name),
      p_mark_verified
    )
    returning id into v_promoter_id;
  else
    update public.promoters
    set display_name = coalesce(
          nullif(trim(public.promoters.display_name), ''),
          v_display_name
        ),
        instagram_handle = coalesce(
          nullif(trim(public.promoters.instagram_handle), ''),
          v_instagram_handle
        ),
        is_verified = public.promoters.is_verified or p_mark_verified
    where id = v_promoter_id;
  end if;

  return v_promoter_id;
end;
$$;

create or replace function public.sync_approved_promoter_request_for_profile(
  p_profile_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles%rowtype;
  v_request public.promoter_access_requests%rowtype;
  v_promoter_id uuid;
begin
  select *
  into v_profile
  from public.profiles
  where id = p_profile_id;

  if v_profile.id is null then
    return null;
  end if;

  select *
  into v_request
  from public.promoter_access_requests
  where status = 'approved'
    and (
      requester_profile_id = p_profile_id
      or (
        nullif(trim(coalesce(v_profile.email, '')), '') is not null
        and lower(email) = lower(v_profile.email)
      )
    )
  order by coalesce(reviewed_at, created_at) desc, created_at desc
  limit 1;

  if v_request.id is null then
    return null;
  end if;

  if v_request.requester_profile_id is distinct from p_profile_id then
    update public.promoter_access_requests
    set requester_profile_id = p_profile_id
    where id = v_request.id;
  end if;

  update public.profiles
  set role = 'promoter'
  where id = p_profile_id
    and role is distinct from 'promoter';

  v_promoter_id := public.ensure_promoter_profile_row(
    p_profile_id,
    v_request.full_name,
    v_request.instagram_handle,
    false
  );

  return v_promoter_id;
end;
$$;

create or replace function public.handle_promoter_access_request_activation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
begin
  if new.status <> 'approved' then
    return new;
  end if;

  v_profile_id := new.requester_profile_id;

  if v_profile_id is null then
    select p.id
    into v_profile_id
    from public.profiles p
    where lower(coalesce(p.email, '')) = lower(new.email)
    order by p.created_at desc
    limit 1;
  end if;

  if v_profile_id is null then
    return new;
  end if;

  if new.requester_profile_id is distinct from v_profile_id then
    update public.promoter_access_requests
    set requester_profile_id = v_profile_id
    where id = new.id;
  end if;

  perform public.sync_approved_promoter_request_for_profile(v_profile_id);
  return new;
end;
$$;

drop trigger if exists promoter_access_requests_activate_promoter
on public.promoter_access_requests;

create trigger promoter_access_requests_activate_promoter
after insert or update of status, requester_profile_id, email
on public.promoter_access_requests
for each row execute procedure public.handle_promoter_access_request_activation();

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
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, 'user'), '@', 1)
    ),
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

  return new;
end;
$$;

create or replace function public.sync_profile_role_to_promoter_row()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role = 'promoter' then
    perform public.ensure_promoter_profile_row(
      new.id,
      new.full_name,
      null,
      false
    );
  else
    delete from public.promoters
    where profile_id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_sync_promoter_role
on public.profiles;

create trigger profiles_sync_promoter_role
after insert or update of role
on public.profiles
for each row execute procedure public.sync_profile_role_to_promoter_row();

create or replace function public.sync_promoter_row_to_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    update public.profiles
    set role = 'user'
    where id = old.profile_id
      and role = 'promoter';

    return old;
  end if;

  update public.profiles
  set role = 'promoter'
  where id = new.profile_id
    and role is distinct from 'promoter';

  if tg_op = 'UPDATE'
     and old.profile_id is distinct from new.profile_id then
    update public.profiles
    set role = 'user'
    where id = old.profile_id
      and role = 'promoter'
      and not exists (
        select 1
        from public.promoters p
        where p.profile_id = old.profile_id
          and p.id <> new.id
      );
  end if;

  return new;
end;
$$;

drop trigger if exists promoters_sync_profile_role
on public.promoters;

create trigger promoters_sync_profile_role
after insert or update of profile_id or delete
on public.promoters
for each row execute procedure public.sync_promoter_row_to_profile_role();

create or replace function public.handle_promoter_delete_cleanup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.event_offers
  set promoter_id = null,
      is_active = false,
      valid_until = coalesce(valid_until, timezone('utc', now()))
  where promoter_id = old.id;

  update public.events
  set contact_promoter_id = null,
      contact_name = case
        when nullif(trim(coalesce(contact_name, '')), '') =
             nullif(trim(coalesce(old.display_name, '')), '')
          then null
        else contact_name
      end,
      allow_whatsapp_requests = false,
      allow_inbox_requests = false
  where contact_promoter_id = old.id;

  return old;
end;
$$;

drop trigger if exists promoters_cleanup_before_delete
on public.promoters;

create trigger promoters_cleanup_before_delete
before delete on public.promoters
for each row execute procedure public.handle_promoter_delete_cleanup();

create or replace function public.handle_event_consistency_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_contact_name text;
begin
  new.event_date := timezone('utc', new.starts_at)::date;

  if new.contact_promoter_id is not null
     and not public.is_active_venue_promoter(new.venue_id, new.contact_promoter_id) then
    select p.display_name
    into v_contact_name
    from public.promoters p
    where p.id = new.contact_promoter_id;

    if nullif(trim(coalesce(new.contact_name, '')), '') =
       nullif(trim(coalesce(v_contact_name, '')), '') then
      new.contact_name := null;
    end if;

    new.contact_promoter_id := null;
    new.allow_whatsapp_requests := false;
    new.allow_inbox_requests := false;
  end if;

  return new;
end;
$$;

drop trigger if exists events_consistency_before_write
on public.events;

create trigger events_consistency_before_write
before insert or update
on public.events
for each row execute procedure public.handle_event_consistency_before_write();

create or replace function public.handle_event_consistency_after_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.venue_id is distinct from new.venue_id then
    update public.table_bookings
    set venue_id = new.venue_id
    where event_id = new.id
      and venue_id is distinct from new.venue_id;

    update public.checkins
    set venue_id = new.venue_id
    where event_id = new.id
      and venue_id is distinct from new.venue_id;

    update public.radar_signals
    set venue_id = new.venue_id
    where event_id = new.id
      and venue_id is distinct from new.venue_id;

    update public.event_offers eo
    set is_active = false,
        valid_until = coalesce(eo.valid_until, timezone('utc', now()))
    where eo.event_id = new.id
      and eo.is_active = true
      and (
        eo.promoter_id is null
        or not public.is_active_venue_promoter(new.venue_id, eo.promoter_id)
      );
  end if;

  if new.status in ('cancelled', 'completed')
     and old.status is distinct from new.status then
    update public.event_offers
    set is_active = false,
        valid_until = coalesce(valid_until, timezone('utc', now()))
    where event_id = new.id
      and is_active = true;

    update public.promoter_contact_requests
    set status = 'closed'
    where event_id = new.id
      and status <> 'closed';
  end if;

  return new;
end;
$$;

drop trigger if exists events_consistency_after_write
on public.events;

create trigger events_consistency_after_write
after update of venue_id, status
on public.events
for each row execute procedure public.handle_event_consistency_after_write();

create or replace function public.handle_event_offer_consistency_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_venue_id uuid;
  v_event_status public.event_status;
begin
  select e.venue_id, e.status
  into v_event_venue_id, v_event_status
  from public.events e
  where e.id = new.event_id;

  if v_event_venue_id is null then
    raise exception 'Event not found for offer';
  end if;

  if new.promoter_id is null then
    new.is_active := false;
    new.valid_until := coalesce(new.valid_until, timezone('utc', now()));
    return new;
  end if;

  if v_event_status in ('cancelled', 'completed') then
    new.is_active := false;
    new.valid_until := coalesce(new.valid_until, timezone('utc', now()));
    return new;
  end if;

  if new.is_active
     and not public.is_active_venue_promoter(v_event_venue_id, new.promoter_id) then
    raise exception 'Offer promoter must be active for the event venue';
  end if;

  if not new.is_active then
    new.valid_until := coalesce(new.valid_until, timezone('utc', now()));
  end if;

  return new;
end;
$$;

drop trigger if exists event_offers_consistency_before_write
on public.event_offers;

create trigger event_offers_consistency_before_write
before insert or update of event_id, promoter_id, is_active, valid_until
on public.event_offers
for each row execute procedure public.handle_event_offer_consistency_before_write();

create or replace function public.handle_reservation_consistency_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_venue_id uuid;
  v_event_starts_at timestamptz;
  v_offer_event_id uuid;
  v_offer_promoter_id uuid;
  v_offer_valid_until timestamptz;
begin
  if new.offer_id is not null then
    select eo.event_id, eo.promoter_id, eo.valid_until
    into v_offer_event_id, v_offer_promoter_id, v_offer_valid_until
    from public.event_offers eo
    where eo.id = new.offer_id;

    if v_offer_event_id is null then
      raise exception 'Offer not found for reservation';
    end if;

    new.event_id := v_offer_event_id;
    new.promoter_id := coalesce(v_offer_promoter_id, new.promoter_id);
  end if;

  select e.venue_id, e.starts_at
  into v_event_venue_id, v_event_starts_at
  from public.events e
  where e.id = new.event_id;

  if v_event_venue_id is null then
    raise exception 'Event not found for reservation';
  end if;

  if new.offer_id is null
     and new.promoter_id is not null
     and not public.is_active_venue_promoter(v_event_venue_id, new.promoter_id) then
    raise exception 'Reservation promoter must be active for the event venue';
  end if;

  if new.qr_expires_at is null then
    new.qr_expires_at := coalesce(
      v_offer_valid_until,
      v_event_starts_at + interval '4 hours'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists reservations_consistency_before_write
on public.reservations;

create trigger reservations_consistency_before_write
before insert or update of event_id, offer_id, promoter_id, qr_expires_at
on public.reservations
for each row execute procedure public.handle_reservation_consistency_before_write();

create or replace function public.handle_table_booking_consistency_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_venue_id uuid;
begin
  select e.venue_id
  into v_event_venue_id
  from public.events e
  where e.id = new.event_id;

  if v_event_venue_id is null then
    raise exception 'Event not found for table booking';
  end if;

  new.venue_id := v_event_venue_id;

  if new.promoter_id is not null
     and not public.is_active_venue_promoter(v_event_venue_id, new.promoter_id) then
    raise exception 'Table booking promoter must be active for the event venue';
  end if;

  return new;
end;
$$;

drop trigger if exists table_bookings_consistency_before_write
on public.table_bookings;

create trigger table_bookings_consistency_before_write
before insert or update of event_id, venue_id, promoter_id
on public.table_bookings
for each row execute procedure public.handle_table_booking_consistency_before_write();

create or replace function public.handle_checkin_consistency_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_id uuid;
  v_venue_id uuid;
  v_party_size integer;
begin
  select r.event_id, r.party_size
  into v_event_id, v_party_size
  from public.reservations r
  where r.id = new.reservation_id;

  if v_event_id is null then
    raise exception 'Reservation not found for check-in';
  end if;

  select e.venue_id
  into v_venue_id
  from public.events e
  where e.id = v_event_id;

  if v_venue_id is null then
    raise exception 'Event not found for check-in';
  end if;

  if new.party_checked_in > v_party_size then
    raise exception 'Checked-in guests exceed reservation party size';
  end if;

  new.event_id := v_event_id;
  new.venue_id := v_venue_id;

  return new;
end;
$$;

drop trigger if exists checkins_consistency_before_write
on public.checkins;

create trigger checkins_consistency_before_write
before insert or update of reservation_id, event_id, venue_id, party_checked_in
on public.checkins
for each row execute procedure public.handle_checkin_consistency_before_write();

create or replace function public.handle_radar_signal_consistency_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_venue_id uuid;
begin
  select e.venue_id
  into v_venue_id
  from public.events e
  where e.id = new.event_id;

  if v_venue_id is null then
    raise exception 'Event not found for radar signal';
  end if;

  new.venue_id := v_venue_id;
  return new;
end;
$$;

drop trigger if exists radar_signals_consistency_before_write
on public.radar_signals;

create trigger radar_signals_consistency_before_write
before insert or update of event_id, venue_id
on public.radar_signals
for each row execute procedure public.handle_radar_signal_consistency_before_write();

create or replace function public.handle_promoter_contact_request_consistency_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer_event_id uuid;
  v_offer_promoter_id uuid;
  v_event_contact_promoter_id uuid;
begin
  if new.offer_id is not null then
    select eo.event_id, eo.promoter_id
    into v_offer_event_id, v_offer_promoter_id
    from public.event_offers eo
    where eo.id = new.offer_id;

    if v_offer_event_id is null then
      raise exception 'Offer not found for promoter contact request';
    end if;

    if v_offer_event_id <> new.event_id then
      raise exception 'Offer does not belong to the selected event';
    end if;

    if v_offer_promoter_id is null then
      raise exception 'Offer promoter is not available';
    end if;

    new.promoter_id := v_offer_promoter_id;
    return new;
  end if;

  select e.contact_promoter_id
  into v_event_contact_promoter_id
  from public.events e
  where e.id = new.event_id;

  if v_event_contact_promoter_id is null
     or v_event_contact_promoter_id <> new.promoter_id then
    if not exists (
      select 1
      from public.event_offers eo
      where eo.event_id = new.event_id
        and eo.promoter_id = new.promoter_id
        and eo.is_active = true
    ) then
      raise exception 'Promoter is not active for the selected event';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists promoter_contact_requests_consistency_before_write
on public.promoter_contact_requests;

create trigger promoter_contact_requests_consistency_before_write
before insert or update of event_id, offer_id, promoter_id
on public.promoter_contact_requests
for each row execute procedure public.handle_promoter_contact_request_consistency_before_write();

create or replace function public.handle_venue_promoter_detach_cleanup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_display_name text;
begin
  if tg_op = 'UPDATE' then
    if old.is_active = false then
      return new;
    end if;

    if new.is_active = true
       and old.venue_id is not distinct from new.venue_id
       and old.promoter_id is not distinct from new.promoter_id then
      return new;
    end if;
  end if;

  select p.display_name
  into v_display_name
  from public.promoters p
  where p.id = old.promoter_id;

  update public.event_offers eo
  set is_active = false,
      valid_until = coalesce(eo.valid_until, timezone('utc', now()))
  where eo.promoter_id = old.promoter_id
    and eo.is_active = true
    and eo.event_id in (
      select e.id
      from public.events e
      where e.venue_id = old.venue_id
    );

  update public.events
  set contact_promoter_id = null,
      contact_name = case
        when nullif(trim(coalesce(contact_name, '')), '') =
             nullif(trim(coalesce(v_display_name, '')), '')
          then null
        else contact_name
      end,
      allow_whatsapp_requests = false,
      allow_inbox_requests = false
  where venue_id = old.venue_id
    and contact_promoter_id = old.promoter_id;

  update public.promoter_contact_requests
  set status = 'closed'
  where promoter_id = old.promoter_id
    and status <> 'closed'
    and event_id in (
      select e.id
      from public.events e
      where e.venue_id = old.venue_id
    );

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists venue_promoters_detach_cleanup
on public.venue_promoters;

create trigger venue_promoters_detach_cleanup
after update of is_active, venue_id, promoter_id or delete
on public.venue_promoters
for each row execute procedure public.handle_venue_promoter_detach_cleanup();
