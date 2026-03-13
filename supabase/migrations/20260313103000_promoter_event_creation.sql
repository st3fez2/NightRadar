create or replace function public.can_create_event_for_venue(target_venue_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.can_manage_venue(target_venue_id)
    or exists (
      select 1
      from public.venue_promoters vp
      where vp.venue_id = target_venue_id
        and vp.promoter_id = public.current_user_promoter_id()
        and vp.is_active = true
    );
$$;

create policy "events insert by promoters"
on public.events for insert to authenticated
with check (public.can_create_event_for_venue(venue_id));

create policy "events update by promoters"
on public.events for update to authenticated
using (public.can_manage_event(id) or public.can_promote_event(id))
with check (public.can_manage_event(id) or public.can_promote_event(id));
