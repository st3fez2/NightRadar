create table if not exists public.event_likes (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  viewer_token text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint event_likes_event_viewer_unique unique (event_id, viewer_token)
);

create index if not exists idx_event_likes_event_id
  on public.event_likes (event_id);

create index if not exists idx_event_likes_viewer_token
  on public.event_likes (viewer_token);

alter table public.event_likes enable row level security;

create or replace view public.event_like_totals as
select
  e.id as event_id,
  coalesce(count(el.id), 0)::integer as like_count
from public.events e
left join public.event_likes el on el.event_id = e.id
group by e.id;

grant select on public.event_like_totals to anon, authenticated;
