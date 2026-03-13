create table if not exists public.promoter_reactions (
  id uuid primary key default gen_random_uuid(),
  promoter_id uuid not null references public.promoters (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  reaction_type text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint promoter_reactions_type_check
    check (reaction_type in ('thumbs_up', 'heart')),
  unique (promoter_id, profile_id, reaction_type)
);

create index if not exists idx_promoter_reactions_promoter
  on public.promoter_reactions (promoter_id, created_at desc);

create index if not exists idx_promoter_reactions_profile
  on public.promoter_reactions (profile_id, created_at desc);

alter table public.promoter_reactions enable row level security;

create or replace view public.promoter_reaction_totals
with (security_invoker = false)
as
select
  promoter_id,
  count(*) filter (where reaction_type = 'thumbs_up')::integer as thumbs_up_count,
  count(*) filter (where reaction_type = 'heart')::integer as heart_count
from public.promoter_reactions
group by promoter_id;

grant select on public.promoter_reaction_totals to anon, authenticated;

create policy "promoter reactions own select"
on public.promoter_reactions for select to authenticated
using (profile_id = auth.uid());

create policy "promoter reactions own insert"
on public.promoter_reactions for insert to authenticated
with check (profile_id = auth.uid());

create policy "promoter reactions own delete"
on public.promoter_reactions for delete to authenticated
using (profile_id = auth.uid());
