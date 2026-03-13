drop policy if exists "events insert by promoters" on public.events;
drop policy if exists "events update by promoters" on public.events;

create policy "events insert by promoters"
on public.events for insert to authenticated
with check (
  public.can_manage_venue(venue_id)
  or exists (
    select 1
    from public.venue_promoters vp
    join public.promoters p on p.id = vp.promoter_id
    where vp.venue_id = public.events.venue_id
      and vp.is_active = true
      and p.profile_id = auth.uid()
  )
);

create policy "events update by promoters"
on public.events for update to authenticated
using (
  public.can_manage_venue(venue_id)
  or exists (
    select 1
    from public.venue_promoters vp
    join public.promoters p on p.id = vp.promoter_id
    where vp.venue_id = public.events.venue_id
      and vp.is_active = true
      and p.profile_id = auth.uid()
  )
)
with check (
  public.can_manage_venue(venue_id)
  or exists (
    select 1
    from public.venue_promoters vp
    join public.promoters p on p.id = vp.promoter_id
    where vp.venue_id = public.events.venue_id
      and vp.is_active = true
      and p.profile_id = auth.uid()
  )
);

drop policy if exists "offers manage" on public.event_offers;

create policy "offers manage"
on public.event_offers for all to authenticated
using (
  public.can_manage_event(event_id)
  or exists (
    select 1
    from public.events e
    join public.venue_promoters vp
      on vp.venue_id = e.venue_id
     and vp.is_active = true
    join public.promoters p on p.id = vp.promoter_id
    where e.id = event_id
      and p.profile_id = auth.uid()
  )
)
with check (
  public.can_manage_event(event_id)
  or exists (
    select 1
    from public.events e
    join public.venue_promoters vp
      on vp.venue_id = e.venue_id
     and vp.is_active = true
    join public.promoters p on p.id = vp.promoter_id
    where e.id = event_id
      and p.profile_id = auth.uid()
  )
);
