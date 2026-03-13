alter table public.events
  add column if not exists minimum_age integer,
  add column if not exists contact_promoter_id uuid references public.promoters (id) on delete set null,
  add column if not exists contact_name text,
  add column if not exists contact_phone text,
  add column if not exists contact_email text,
  add column if not exists allow_whatsapp_requests boolean not null default false,
  add column if not exists allow_inbox_requests boolean not null default true,
  add column if not exists allow_email_requests boolean not null default false;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'events_minimum_age_check'
  ) then
    alter table public.events
      add constraint events_minimum_age_check
      check (minimum_age is null or minimum_age between 14 and 25);
  end if;
end
$$;

update public.events e
set
  contact_promoter_id = coalesce(
    e.contact_promoter_id,
    (
      select p.id
      from public.promoters p
      where p.profile_id = e.created_by
      limit 1
    )
  ),
  contact_name = coalesce(
    nullif(trim(e.contact_name), ''),
    (
      select p.display_name
      from public.promoters p
      where p.id = e.contact_promoter_id
      limit 1
    ),
    (
      select p.display_name
      from public.promoters p
      where p.profile_id = e.created_by
      limit 1
    )
  );

create table if not exists public.promoter_contact_requests (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  promoter_id uuid not null references public.promoters (id) on delete cascade,
  offer_id uuid references public.event_offers (id) on delete set null,
  requester_profile_id uuid references public.profiles (id) on delete set null,
  requester_name text not null,
  requester_email text,
  requester_phone text,
  party_size integer not null default 1,
  message text not null,
  reply_preference text not null default 'whatsapp',
  status text not null default 'new',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint promoter_contact_requests_party_size_check
    check (party_size between 1 and 30),
  constraint promoter_contact_requests_message_check
    check (char_length(trim(message)) >= 4),
  constraint promoter_contact_requests_requester_name_check
    check (char_length(trim(requester_name)) >= 2),
  constraint promoter_contact_requests_reply_preference_check
    check (reply_preference in ('whatsapp', 'email', 'inbox')),
  constraint promoter_contact_requests_status_check
    check (status in ('new', 'contacted', 'closed')),
  constraint promoter_contact_requests_contact_check
    check (
      nullif(trim(coalesce(requester_email, '')), '') is not null
      or nullif(trim(coalesce(requester_phone, '')), '') is not null
    )
);

create index if not exists idx_promoter_contact_requests_promoter
  on public.promoter_contact_requests (promoter_id, created_at desc);

create index if not exists idx_promoter_contact_requests_event
  on public.promoter_contact_requests (event_id, created_at desc);

create trigger promoter_contact_requests_set_updated_at
before update on public.promoter_contact_requests
for each row execute procedure public.set_updated_at();

alter table public.promoter_contact_requests enable row level security;

create policy "promoter contact requests insert public"
on public.promoter_contact_requests for insert to anon, authenticated
with check (
  exists (
    select 1
    from public.events e
    where e.id = event_id
      and e.is_public = true
      and (
        (
          e.allow_inbox_requests = true
          and e.contact_promoter_id = promoter_id
        )
        or exists (
          select 1
          from public.event_offers eo
          where eo.event_id = event_id
            and eo.promoter_id = promoter_id
            and eo.is_active = true
            and (offer_id is null or eo.id = offer_id)
        )
      )
  )
);

create policy "promoter contact requests select related"
on public.promoter_contact_requests for select to authenticated
using (
  promoter_id = public.current_user_promoter_id()
  or public.can_manage_event(event_id)
);

create policy "promoter contact requests update related"
on public.promoter_contact_requests for update to authenticated
using (
  promoter_id = public.current_user_promoter_id()
  or public.can_manage_event(event_id)
)
with check (
  promoter_id = public.current_user_promoter_id()
  or public.can_manage_event(event_id)
);
