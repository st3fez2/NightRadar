create extension if not exists pgcrypto;

create type public.app_role as enum ('user', 'promoter', 'venue_admin', 'door_staff', 'super_admin');
create type public.membership_role as enum ('venue_admin', 'door_staff');
create type public.event_status as enum ('draft', 'published', 'live', 'completed', 'cancelled');
create type public.offer_type as enum ('guest_list_free', 'guest_list_reduced', 'table', 'vip_pass', 'ticket');
create type public.reservation_status as enum ('requested', 'approved', 'checked_in', 'rejected', 'cancelled', 'expired', 'no_show');
create type public.table_booking_status as enum ('requested', 'confirmed', 'arrived', 'cancelled', 'no_show');
create type public.checkin_status as enum ('admitted', 'duplicate', 'expired', 'rejected');
create type public.radar_signal_source as enum ('venue_staff', 'promoter_manual', 'user_feedback');
create type public.radar_signal_type as enum ('crowd', 'queue', 'booking_velocity', 'table_pressure');
create type public.crowd_label as enum ('easy', 'active', 'hot', 'near_full');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.radar_label_from_score(score numeric)
returns public.crowd_label
language sql
immutable
as $$
  select case
    when score < 25 then 'easy'::public.crowd_label
    when score < 50 then 'active'::public.crowd_label
    when score < 75 then 'hot'::public.crowd_label
    else 'near_full'::public.crowd_label
  end;
$$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null default 'user',
  full_name text not null,
  email text,
  phone text,
  city text,
  avatar_url text,
  music_preferences text[] not null default '{}'::text[],
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profiles_full_name_check check (char_length(trim(full_name)) >= 2)
);

create table public.promoters (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles (id) on delete cascade,
  display_name text not null,
  bio text,
  rating numeric(3, 2) not null default 0,
  referral_code text not null unique,
  is_verified boolean not null default false,
  is_visible boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint promoters_rating_check check (rating >= 0 and rating <= 5)
);

create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  address_line text not null,
  city text not null,
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  capacity integer not null default 0,
  categories text[] not null default '{}'::text[],
  dress_code text,
  price_band text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint venues_capacity_check check (capacity >= 0)
);

create table public.venue_memberships (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role public.membership_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  unique (venue_id, profile_id, role)
);

create table public.venue_promoters (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  promoter_id uuid not null references public.promoters (id) on delete cascade,
  is_active boolean not null default true,
  commission_per_guest numeric(10, 2) not null default 0,
  commission_per_table numeric(10, 2) not null default 0,
  free_pass_quota integer not null default 0,
  reduced_pass_quota integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (venue_id, promoter_id)
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  title text not null,
  event_date date not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  description text,
  lineup text,
  music_tags text[] not null default '{}'::text[],
  status public.event_status not null default 'draft',
  entry_policy text,
  is_public boolean not null default true,
  cover_image_url text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint events_time_check check (ends_at is null or ends_at > starts_at)
);

create index idx_promoters_profile_id on public.promoters (profile_id);
create index idx_venues_city on public.venues (city);
create index idx_venue_memberships_profile on public.venue_memberships (profile_id, venue_id) where is_active = true;
create index idx_venue_promoters_venue on public.venue_promoters (venue_id, is_active);
create index idx_events_venue on public.events (venue_id, event_date desc);
create index idx_events_status_public on public.events (status, is_public, event_date desc);

create table public.event_offers (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  promoter_id uuid references public.promoters (id) on delete set null,
  type public.offer_type not null,
  title text not null,
  description text,
  price numeric(10, 2) not null default 0,
  capacity_total integer,
  valid_until timestamptz,
  conditions text,
  is_active boolean not null default true,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint event_offers_price_check check (price >= 0),
  constraint event_offers_capacity_check check (capacity_total is null or capacity_total >= 0)
);

create table public.reservations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  offer_id uuid references public.event_offers (id) on delete set null,
  user_id uuid references public.profiles (id) on delete set null,
  promoter_id uuid references public.promoters (id) on delete set null,
  guest_name text not null,
  guest_phone text,
  guest_email text,
  party_size integer not null default 1,
  status public.reservation_status not null default 'requested',
  qr_token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  qr_expires_at timestamptz,
  requested_at timestamptz not null default timezone('utc', now()),
  confirmed_at timestamptz,
  notes text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint reservations_guest_name_check check (char_length(trim(guest_name)) >= 2),
  constraint reservations_party_size_check check (party_size between 1 and 30)
);

create table public.table_bookings (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  venue_id uuid not null references public.venues (id) on delete cascade,
  promoter_id uuid references public.promoters (id) on delete set null,
  user_id uuid references public.profiles (id) on delete set null,
  group_name text not null,
  contact_phone text,
  guest_count integer not null default 1,
  deposit_amount numeric(10, 2) not null default 0,
  minimum_spend numeric(10, 2) not null default 0,
  arrival_time timestamptz,
  status public.table_booking_status not null default 'requested',
  notes text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint table_bookings_guest_count_check check (guest_count between 1 and 30),
  constraint table_bookings_deposit_check check (deposit_amount >= 0),
  constraint table_bookings_spend_check check (minimum_spend >= 0)
);

create table public.checkins (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null unique references public.reservations (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  venue_id uuid not null references public.venues (id) on delete cascade,
  scanned_by uuid references public.profiles (id) on delete set null,
  party_checked_in integer not null default 1,
  status public.checkin_status not null default 'admitted',
  scanned_at timestamptz not null default timezone('utc', now()),
  notes text,
  constraint checkins_party_checked_in_check check (party_checked_in >= 1)
);

create table public.radar_signals (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  venue_id uuid not null references public.venues (id) on delete cascade,
  source public.radar_signal_source not null,
  signal_type public.radar_signal_type not null,
  signal_value numeric(10, 2) not null,
  weight numeric(5, 2) not null default 1,
  note text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint radar_signals_weight_check check (weight > 0)
);

create index idx_event_offers_event on public.event_offers (event_id, is_active);
create index idx_reservations_event_status on public.reservations (event_id, status);
create index idx_reservations_promoter_status on public.reservations (promoter_id, status);
create index idx_reservations_user on public.reservations (user_id, created_at desc);
create index idx_reservations_qr_token on public.reservations (qr_token);
create index idx_table_bookings_event_status on public.table_bookings (event_id, status);
create index idx_checkins_event_time on public.checkins (event_id, scanned_at desc);
create index idx_radar_signals_event_time on public.radar_signals (event_id, created_at desc);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), split_part(coalesce(new.email, 'user'), '@', 1)),
    new.email,
    new.phone
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'super_admin'
  );
$$;

create or replace function public.current_user_promoter_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.promoters p
  where p.profile_id = auth.uid()
  limit 1;
$$;

create or replace function public.can_manage_venue(target_venue_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.venue_memberships vm
    where vm.venue_id = target_venue_id
      and vm.profile_id = auth.uid()
      and vm.role = 'venue_admin'
      and vm.is_active = true
  ) or public.is_super_admin();
$$;

create or replace function public.can_staff_venue(target_venue_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.venue_memberships vm
    where vm.venue_id = target_venue_id
      and vm.profile_id = auth.uid()
      and vm.role in ('venue_admin', 'door_staff')
      and vm.is_active = true
  ) or public.is_super_admin();
$$;

create or replace function public.can_manage_event(target_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    where e.id = target_event_id
      and public.can_manage_venue(e.venue_id)
  ) or public.is_super_admin();
$$;

create or replace function public.can_promote_event(target_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    join public.venue_promoters vp
      on vp.venue_id = e.venue_id
     and vp.promoter_id = public.current_user_promoter_id()
     and vp.is_active = true
    where e.id = target_event_id
  );
$$;

create or replace function public.process_checkin(p_qr_token text, p_party_size integer default 1)
returns table (
  reservation_id uuid,
  event_id uuid,
  venue_id uuid,
  status text,
  message text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reservation public.reservations%rowtype;
  v_event public.events%rowtype;
begin
  select *
  into v_reservation
  from public.reservations
  where qr_token = p_qr_token;

  if not found then
    return query select null::uuid, null::uuid, null::uuid, 'not_found', 'QR non trovato';
    return;
  end if;

  select *
  into v_event
  from public.events
  where id = v_reservation.event_id;

  if v_event.id is null or not public.can_staff_venue(v_event.venue_id) then
    return query select v_reservation.id, v_reservation.event_id, v_event.venue_id, 'forbidden', 'Utente non autorizzato';
    return;
  end if;

  if exists (select 1 from public.checkins c where c.reservation_id = v_reservation.id) then
    return query select v_reservation.id, v_reservation.event_id, v_event.venue_id, 'duplicate', 'QR gia utilizzato';
    return;
  end if;

  if v_reservation.qr_expires_at is not null and v_reservation.qr_expires_at < timezone('utc', now()) then
    update public.reservations
    set status = 'expired'
    where id = v_reservation.id
      and status <> 'checked_in';

    return query select v_reservation.id, v_reservation.event_id, v_event.venue_id, 'expired', 'QR scaduto';
    return;
  end if;

  insert into public.checkins (
    reservation_id,
    event_id,
    venue_id,
    scanned_by,
    party_checked_in,
    status
  )
  values (
    v_reservation.id,
    v_reservation.event_id,
    v_event.venue_id,
    auth.uid(),
    greatest(p_party_size, 1),
    'admitted'
  );

  update public.reservations
  set status = 'checked_in',
      confirmed_at = coalesce(confirmed_at, timezone('utc', now()))
  where id = v_reservation.id;

  return query select v_reservation.id, v_reservation.event_id, v_event.venue_id, 'admitted', 'Ingresso registrato';
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
create trigger promoters_set_updated_at before update on public.promoters for each row execute procedure public.set_updated_at();
create trigger venues_set_updated_at before update on public.venues for each row execute procedure public.set_updated_at();
create trigger venue_promoters_set_updated_at before update on public.venue_promoters for each row execute procedure public.set_updated_at();
create trigger events_set_updated_at before update on public.events for each row execute procedure public.set_updated_at();
create trigger event_offers_set_updated_at before update on public.event_offers for each row execute procedure public.set_updated_at();
create trigger reservations_set_updated_at before update on public.reservations for each row execute procedure public.set_updated_at();
create trigger table_bookings_set_updated_at before update on public.table_bookings for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.promoters enable row level security;
alter table public.venues enable row level security;
alter table public.venue_memberships enable row level security;
alter table public.venue_promoters enable row level security;
alter table public.events enable row level security;
alter table public.event_offers enable row level security;
alter table public.reservations enable row level security;
alter table public.table_bookings enable row level security;
alter table public.checkins enable row level security;
alter table public.radar_signals enable row level security;

create policy "profiles readable by authenticated"
on public.profiles for select to authenticated using (true);

create policy "profiles self update"
on public.profiles for update to authenticated
using (id = auth.uid() or public.is_super_admin())
with check (id = auth.uid() or public.is_super_admin());

create policy "promoters readable by authenticated"
on public.promoters for select to authenticated using (true);

create policy "promoters own insert"
on public.promoters for insert to authenticated
with check (profile_id = auth.uid() or public.is_super_admin());

create policy "promoters own update"
on public.promoters for update to authenticated
using (profile_id = auth.uid() or public.is_super_admin())
with check (profile_id = auth.uid() or public.is_super_admin());

create policy "venues readable by authenticated"
on public.venues for select to authenticated using (true);

create policy "venues insert by authenticated"
on public.venues for insert to authenticated
with check (created_by = auth.uid() or created_by is null or public.is_super_admin());

create policy "venues update by admins"
on public.venues for update to authenticated
using (public.can_manage_venue(id))
with check (public.can_manage_venue(id));

create policy "venue memberships select"
on public.venue_memberships for select to authenticated
using (profile_id = auth.uid() or public.can_manage_venue(venue_id));

create policy "venue memberships manage"
on public.venue_memberships for all to authenticated
using (public.can_manage_venue(venue_id))
with check (public.can_manage_venue(venue_id));

create policy "venue promoters select"
on public.venue_promoters for select to authenticated using (true);

create policy "venue promoters manage"
on public.venue_promoters for all to authenticated
using (public.can_manage_venue(venue_id))
with check (public.can_manage_venue(venue_id));

create policy "events select"
on public.events for select to authenticated
using (is_public = true or public.can_manage_event(id) or public.can_promote_event(id));

create policy "events manage"
on public.events for all to authenticated
using (public.can_manage_venue(venue_id))
with check (public.can_manage_venue(venue_id));

create policy "offers select"
on public.event_offers for select to authenticated
using (
  exists (
    select 1 from public.events e
    where e.id = event_id and (e.is_public = true or public.can_manage_event(e.id) or public.can_promote_event(e.id))
  )
);

create policy "offers manage"
on public.event_offers for all to authenticated
using (public.can_manage_event(event_id) or public.can_promote_event(event_id))
with check (public.can_manage_event(event_id) or public.can_promote_event(event_id));

create policy "reservations select related"
on public.reservations for select to authenticated
using (
  user_id = auth.uid()
  or created_by = auth.uid()
  or promoter_id = public.current_user_promoter_id()
  or public.can_manage_event(event_id)
  or public.can_promote_event(event_id)
);

create policy "reservations insert authenticated"
on public.reservations for insert to authenticated
with check (
  created_by = auth.uid()
  or user_id = auth.uid()
  or promoter_id = public.current_user_promoter_id()
  or public.can_manage_event(event_id)
  or public.can_promote_event(event_id)
);

create policy "reservations update related"
on public.reservations for update to authenticated
using (
  user_id = auth.uid()
  or created_by = auth.uid()
  or promoter_id = public.current_user_promoter_id()
  or public.can_manage_event(event_id)
  or public.can_promote_event(event_id)
)
with check (
  user_id = auth.uid()
  or created_by = auth.uid()
  or promoter_id = public.current_user_promoter_id()
  or public.can_manage_event(event_id)
  or public.can_promote_event(event_id)
);

create policy "table bookings select related"
on public.table_bookings for select to authenticated
using (
  user_id = auth.uid()
  or created_by = auth.uid()
  or promoter_id = public.current_user_promoter_id()
  or public.can_staff_venue(venue_id)
);

create policy "table bookings manage related"
on public.table_bookings for all to authenticated
using (
  user_id = auth.uid()
  or created_by = auth.uid()
  or promoter_id = public.current_user_promoter_id()
  or public.can_staff_venue(venue_id)
)
with check (
  user_id = auth.uid()
  or created_by = auth.uid()
  or promoter_id = public.current_user_promoter_id()
  or public.can_staff_venue(venue_id)
);

create policy "checkins select by venue staff"
on public.checkins for select to authenticated
using (public.can_staff_venue(venue_id));

create policy "radar signals select"
on public.radar_signals for select to authenticated using (true);

create policy "radar signals insert"
on public.radar_signals for insert to authenticated
with check (public.can_staff_venue(venue_id) or public.can_promote_event(event_id));

create or replace view public.event_offer_availability
with (security_invoker = true)
as
select
  eo.id as offer_id,
  eo.event_id,
  eo.promoter_id,
  eo.type,
  eo.title,
  eo.price,
  eo.capacity_total,
  coalesce(sum(case when r.status in ('requested', 'approved', 'checked_in') then r.party_size else 0 end), 0) as reserved_guests,
  case
    when eo.capacity_total is null then null
    else greatest(eo.capacity_total - coalesce(sum(case when r.status in ('requested', 'approved', 'checked_in') then r.party_size else 0 end), 0), 0)
  end as spots_left
from public.event_offers eo
left join public.reservations r on r.offer_id = eo.id
group by eo.id, eo.event_id, eo.promoter_id, eo.type, eo.title, eo.price, eo.capacity_total;

create or replace view public.event_radar_live
with (security_invoker = true)
as
with reservation_stats as (
  select event_id, coalesce(sum(case when status in ('approved', 'checked_in') then party_size else 0 end), 0) as approved_guests
  from public.reservations
  group by event_id
),
checkin_stats as (
  select event_id, coalesce(sum(case when status = 'admitted' then party_checked_in else 0 end), 0) as checked_in_guests
  from public.checkins
  group by event_id
),
table_stats as (
  select event_id, count(*) filter (where status in ('confirmed', 'arrived')) as confirmed_tables
  from public.table_bookings
  group by event_id
),
signal_stats as (
  select event_id, coalesce(sum(least(signal_value, 5) * weight), 0) as signal_points
  from public.radar_signals
  where created_at >= timezone('utc', now()) - interval '3 hours'
  group by event_id
)
select
  e.id as event_id,
  e.venue_id,
  v.name as venue_name,
  v.city,
  e.title,
  e.event_date,
  e.starts_at,
  e.status,
  v.capacity,
  coalesce(r.approved_guests, 0) as approved_guests,
  coalesce(c.checked_in_guests, 0) as checked_in_guests,
  coalesce(t.confirmed_tables, 0) as confirmed_tables,
  least(
    100::numeric,
    least(45::numeric, (coalesce(r.approved_guests, 0)::numeric / greatest(v.capacity, 1)) * 45)
    + least(35::numeric, (coalesce(c.checked_in_guests, 0)::numeric / greatest(v.capacity, 1)) * 35)
    + least(10::numeric, coalesce(t.confirmed_tables, 0)::numeric * 2.5)
    + least(10::numeric, coalesce(s.signal_points, 0))
  ) as radar_score,
  public.radar_label_from_score(
    least(
      100::numeric,
      least(45::numeric, (coalesce(r.approved_guests, 0)::numeric / greatest(v.capacity, 1)) * 45)
      + least(35::numeric, (coalesce(c.checked_in_guests, 0)::numeric / greatest(v.capacity, 1)) * 35)
      + least(10::numeric, coalesce(t.confirmed_tables, 0)::numeric * 2.5)
      + least(10::numeric, coalesce(s.signal_points, 0))
    )
  ) as radar_label
from public.events e
join public.venues v on v.id = e.venue_id
left join reservation_stats r on r.event_id = e.id
left join checkin_stats c on c.event_id = e.id
left join table_stats t on t.event_id = e.id
left join signal_stats s on s.event_id = e.id;

grant execute on function public.process_checkin(text, integer) to authenticated;
grant select on public.event_offer_availability to authenticated;
grant select on public.event_radar_live to authenticated;
