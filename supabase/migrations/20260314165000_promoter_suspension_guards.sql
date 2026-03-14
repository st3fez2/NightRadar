alter table public.promoters
  add column if not exists is_suspended boolean not null default false,
  add column if not exists suspended_at timestamptz,
  add column if not exists suspension_reason text;

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
    and coalesce(p.is_suspended, false) = false
  limit 1;
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
    join public.promoters p
      on p.id = vp.promoter_id
    where vp.venue_id = p_venue_id
      and vp.promoter_id = p_promoter_id
      and vp.is_active = true
      and coalesce(p.is_suspended, false) = false
  );
$$;

drop policy if exists "promoters public readable by anon"
on public.promoters;

create policy "promoters public readable by anon"
on public.promoters for select to anon
using (
  is_visible = true
  and coalesce(is_suspended, false) = false
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

create or replace function public.handle_promoter_suspension_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_suspended then
    if (tg_op = 'INSERT' or old.is_suspended is distinct from true)
       and new.suspended_at is null then
      new.suspended_at := timezone('utc', now());
    end if;

    if nullif(trim(coalesce(new.suspension_reason, '')), '') is null then
      new.suspension_reason := null;
    end if;
  else
    new.suspended_at := null;
    new.suspension_reason := null;
  end if;

  return new;
end;
$$;

drop trigger if exists promoters_suspension_before_write
on public.promoters;

create trigger promoters_suspension_before_write
before insert or update of is_suspended, suspended_at, suspension_reason
on public.promoters
for each row execute procedure public.handle_promoter_suspension_before_write();

create or replace function public.handle_promoter_suspension_after_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not new.is_suspended
     or old.is_suspended is not distinct from new.is_suspended then
    return new;
  end if;

  update public.venue_promoters
  set is_active = false
  where promoter_id = new.id
    and is_active = true;

  update public.event_offers
  set is_active = false,
      valid_until = coalesce(valid_until, timezone('utc', now()))
  where promoter_id = new.id
    and is_active = true;

  update public.events
  set contact_promoter_id = null,
      contact_name = case
        when nullif(trim(coalesce(contact_name, '')), '') =
             nullif(trim(coalesce(new.display_name, '')), '')
          then null
        else contact_name
      end,
      allow_whatsapp_requests = false,
      allow_inbox_requests = false,
      allow_email_requests = false
  where contact_promoter_id = new.id;

  update public.promoter_contact_requests
  set status = 'closed'
  where promoter_id = new.id
    and status <> 'closed';

  return new;
end;
$$;

drop trigger if exists promoters_suspension_after_write
on public.promoters;

create trigger promoters_suspension_after_write
after update of is_suspended
on public.promoters
for each row execute procedure public.handle_promoter_suspension_after_write();
