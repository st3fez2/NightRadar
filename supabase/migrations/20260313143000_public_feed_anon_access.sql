create policy "venues public readable by anon"
on public.venues for select to anon
using (
  exists (
    select 1
    from public.events e
    where e.venue_id = venues.id
      and e.is_public = true
      and e.status in ('published', 'live')
  )
);

create policy "events public readable by anon"
on public.events for select to anon
using (is_public = true and status in ('published', 'live'));

create policy "offers public readable by anon"
on public.event_offers for select to anon
using (
  is_active = true
  and exists (
    select 1
    from public.events e
    where e.id = event_id
      and e.is_public = true
      and e.status in ('published', 'live')
  )
);

alter view public.event_offer_availability set (security_invoker = false);
alter view public.event_radar_live set (security_invoker = false);

grant select on public.event_offer_availability to anon;
grant select on public.event_radar_live to anon;
