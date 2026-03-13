drop policy "promoter access requests insert"
on public.promoter_access_requests;

create policy "promoter access requests insert"
on public.promoter_access_requests for insert to anon, authenticated
with check (true);
