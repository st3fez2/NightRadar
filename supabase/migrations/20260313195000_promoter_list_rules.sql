alter table public.event_offers
  add column if not exists collect_last_name boolean not null default false,
  add column if not exists phone_requirement text not null default 'lead',
  add column if not exists allow_anonymous_entry boolean not null default false,
  add column if not exists requires_list_name boolean not null default false;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'event_offers_phone_requirement_check'
  ) then
    alter table public.event_offers
      add constraint event_offers_phone_requirement_check
      check (phone_requirement in ('none', 'lead', 'all_participants'));
  end if;
end $$;

alter table public.reservations
  add column if not exists guest_last_name text,
  add column if not exists list_name text,
  add column if not exists is_anonymous_entry boolean not null default false,
  add column if not exists participant_details jsonb not null default '[]'::jsonb;

update public.event_offers
set phone_requirement = 'lead'
where phone_requirement is null;

update public.reservations
set participant_details = '[]'::jsonb
where participant_details is null;
