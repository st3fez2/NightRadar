alter table public.events
  add column if not exists venue_delivery_name text,
  add column if not exists venue_delivery_phone text,
  add column if not exists venue_delivery_email text,
  add column if not exists venue_delivery_telegram text,
  add column if not exists promo_caption text;

create or replace function public.close_expired_events()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  closed_count integer := 0;
begin
  with closed_events as (
    update public.events
    set status = 'completed'
    where status in ('published', 'live')
      and coalesce(ends_at, starts_at + interval '6 hours') < timezone('utc', now())
    returning id
  ), archived_offers as (
  update public.event_offers eo
  set is_active = false
  where eo.is_active = true
    and eo.event_id in (select id from closed_events)
  )
  select count(*)
  into closed_count
  from closed_events;

  return closed_count;
end;
$$;

grant execute on function public.close_expired_events() to authenticated;

create or replace function public.purge_old_events(
  retention interval default interval '6 months'
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer := 0;
begin
  delete from public.events
  where status in ('completed', 'cancelled')
    and coalesce(ends_at, starts_at) < timezone('utc', now()) - retention;

  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

grant execute on function public.purge_old_events(interval) to authenticated;

do $do$
begin
  if exists (
    select 1
    from pg_available_extensions
    where name = 'pg_cron'
  ) then
    begin
      create extension if not exists pg_cron;
    exception
      when insufficient_privilege then
        null;
    end;
  end if;
end $do$;

do $do$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    execute $cmd$
      select cron.unschedule(jobid)
      from cron.job
      where jobname in (
        'nightradar-close-expired-events',
        'nightradar-purge-old-events'
      )
    $cmd$;

    execute $cmd$
      select cron.schedule(
        'nightradar-close-expired-events',
        '15 * * * *',
        $$select public.close_expired_events();$$
      )
    $cmd$;

    execute $cmd$
      select cron.schedule(
        'nightradar-purge-old-events',
        '30 4 * * *',
        $$select public.purge_old_events(interval '6 months');$$
      )
    $cmd$;
  end if;
end $do$;
