alter table public.event_offers
  add column if not exists show_qr_on_entry boolean not null default true,
  add column if not exists show_secret_code_on_entry boolean not null default false,
  add column if not exists show_list_name_on_entry boolean not null default false;

update public.event_offers
set show_list_name_on_entry = true
where requires_list_name = true
  and show_list_name_on_entry = false;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'event_offers_entry_credential_check'
  ) then
    alter table public.event_offers
      add constraint event_offers_entry_credential_check
      check (
        show_qr_on_entry
        or show_secret_code_on_entry
        or show_list_name_on_entry
      );
  end if;
end $$;

alter table public.reservations
  add column if not exists guest_access_type text not null default 'verified_user',
  add column if not exists entry_secret_code text not null default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));

update public.reservations
set guest_access_type = case
  when user_id is null then 'anonymous_guest'
  else 'verified_user'
end
where guest_access_type is null
   or guest_access_type not in ('verified_user', 'anonymous_guest');

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'reservations_guest_access_type_check'
  ) then
    alter table public.reservations
      add constraint reservations_guest_access_type_check
      check (guest_access_type in ('verified_user', 'anonymous_guest'));
  end if;
end $$;

create or replace function public.promoter_upsert_event_offer_v3(
  p_offer_id uuid default null,
  p_event_id uuid default null,
  p_title text default null,
  p_type public.offer_type default 'guest_list_reduced',
  p_price numeric default 0,
  p_capacity_total integer default null,
  p_table_guest_capacity integer default null,
  p_description text default null,
  p_conditions text default null,
  p_valid_until timestamptz default null,
  p_collect_last_name boolean default false,
  p_phone_requirement text default 'lead',
  p_allow_anonymous_entry boolean default false,
  p_requires_list_name boolean default false,
  p_show_public_availability boolean default false,
  p_show_qr_on_entry boolean default true,
  p_show_secret_code_on_entry boolean default false,
  p_show_list_name_on_entry boolean default false
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
  if not p_show_qr_on_entry and not p_show_secret_code_on_entry and not p_show_list_name_on_entry then
    raise exception 'At least one entrance credential must be visible';
  end if;

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
      table_guest_capacity,
      valid_until,
      conditions,
      collect_last_name,
      phone_requirement,
      allow_anonymous_entry,
      requires_list_name,
      show_public_availability,
      show_qr_on_entry,
      show_secret_code_on_entry,
      show_list_name_on_entry,
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
      case
        when p_type = 'table'::public.offer_type then p_table_guest_capacity
        else null
      end,
      p_valid_until,
      p_conditions,
      p_collect_last_name,
      p_phone_requirement,
      p_allow_anonymous_entry,
      p_requires_list_name,
      p_show_public_availability,
      p_show_qr_on_entry,
      p_show_secret_code_on_entry,
      p_show_list_name_on_entry,
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
      table_guest_capacity = case
        when p_type = 'table'::public.offer_type then p_table_guest_capacity
        else null
      end,
      description = p_description,
      conditions = p_conditions,
      valid_until = p_valid_until,
      collect_last_name = p_collect_last_name,
      phone_requirement = p_phone_requirement,
      allow_anonymous_entry = p_allow_anonymous_entry,
      requires_list_name = p_requires_list_name,
      show_public_availability = p_show_public_availability,
      show_qr_on_entry = p_show_qr_on_entry,
      show_secret_code_on_entry = p_show_secret_code_on_entry,
      show_list_name_on_entry = p_show_list_name_on_entry
    where id = p_offer_id
    returning id into v_offer_id;
  end if;

  return v_offer_id;
end;
$$;

grant execute on function public.promoter_upsert_event_offer_v3(
  uuid,
  uuid,
  text,
  public.offer_type,
  numeric,
  integer,
  integer,
  text,
  text,
  timestamptz,
  boolean,
  text,
  boolean,
  boolean,
  boolean,
  boolean,
  boolean,
  boolean
) to authenticated;
