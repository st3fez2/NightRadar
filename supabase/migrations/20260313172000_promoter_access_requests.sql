create table public.promoter_access_requests (
  id uuid primary key default gen_random_uuid(),
  requester_profile_id uuid references public.profiles (id) on delete set null,
  full_name text not null,
  email text not null,
  city text,
  phone text,
  instagram_handle text,
  experience_note text,
  status text not null default 'requested',
  review_notes text,
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint promoter_access_requests_name_check check (char_length(trim(full_name)) >= 2),
  constraint promoter_access_requests_email_check check (position('@' in email) > 1),
  constraint promoter_access_requests_status_check check (status in ('requested', 'reviewing', 'approved', 'rejected'))
);

create unique index idx_promoter_access_requests_open_email
on public.promoter_access_requests (lower(email))
where status in ('requested', 'reviewing');

create trigger promoter_access_requests_set_updated_at
before update on public.promoter_access_requests
for each row execute procedure public.set_updated_at();

alter table public.promoter_access_requests enable row level security;

create policy "promoter access requests insert"
on public.promoter_access_requests for insert to anon, authenticated
with check (
  (requester_profile_id is null or requester_profile_id = auth.uid())
  and char_length(trim(full_name)) >= 2
  and position('@' in email) > 1
);

create policy "promoter access requests select own"
on public.promoter_access_requests for select to authenticated
using (
  requester_profile_id = auth.uid()
  or lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
);
