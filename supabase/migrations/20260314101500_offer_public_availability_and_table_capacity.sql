alter table public.event_offers
  add column if not exists table_guest_capacity integer,
  add column if not exists show_public_availability boolean not null default false;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'event_offers_table_guest_capacity_check'
  ) then
    alter table public.event_offers
      add constraint event_offers_table_guest_capacity_check
      check (table_guest_capacity is null or table_guest_capacity between 1 and 30);
  end if;
end $$;

drop view if exists public.event_offer_availability;

create view public.event_offer_availability
with (security_invoker = false)
as
select
  eo.id as offer_id,
  eo.event_id,
  eo.promoter_id,
  eo.type,
  eo.title,
  eo.price,
  eo.capacity_total,
  eo.table_guest_capacity,
  eo.show_public_availability,
  coalesce(
    count(*) filter (
      where r.status in ('requested', 'approved', 'checked_in')
    ),
    0
  )::integer as reserved_entries,
  coalesce(
    sum(
      case
        when r.status in ('requested', 'approved', 'checked_in')
          then r.party_size
        else 0
      end
    ),
    0
  )::integer as reserved_guests,
  case
    when eo.capacity_total is null then null
    when eo.type = 'table'::public.offer_type then greatest(
      eo.capacity_total
      - coalesce(
        count(*) filter (
          where r.status in ('requested', 'approved', 'checked_in')
        ),
        0
      )::integer,
      0
    )
    else greatest(
      eo.capacity_total
      - coalesce(
        sum(
          case
            when r.status in ('requested', 'approved', 'checked_in')
              then r.party_size
            else 0
          end
        ),
        0
      )::integer,
      0
    )
  end as spots_left
from public.event_offers eo
left join public.reservations r on r.offer_id = eo.id
group by
  eo.id,
  eo.event_id,
  eo.promoter_id,
  eo.type,
  eo.title,
  eo.price,
  eo.capacity_total,
  eo.table_guest_capacity,
  eo.show_public_availability;

grant select on public.event_offer_availability to authenticated, anon;

create or replace function public.promoter_upsert_event_offer_v2(
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
  p_show_public_availability boolean default false
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
      table_guest_capacity,
      valid_until,
      conditions,
      collect_last_name,
      phone_requirement,
      allow_anonymous_entry,
      requires_list_name,
      show_public_availability,
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
      show_public_availability = p_show_public_availability
    where id = p_offer_id
    returning id into v_offer_id;
  end if;

  return v_offer_id;
end;
$$;

grant execute on function public.promoter_upsert_event_offer_v2(
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
  boolean
) to authenticated;
