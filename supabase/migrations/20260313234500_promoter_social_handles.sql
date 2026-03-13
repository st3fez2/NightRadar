alter table public.promoters
  add column if not exists instagram_handle text,
  add column if not exists tiktok_handle text;

update public.promoters p
set
  instagram_handle = coalesce(
    nullif(trim(p.instagram_handle), ''),
    (
      select nullif(trim(par.instagram_handle), '')
      from public.promoter_access_requests par
      join public.profiles pr on lower(pr.email) = lower(par.email)
      where pr.id = p.profile_id
      order by par.created_at desc
      limit 1
    )
  )
where p.instagram_handle is null or trim(p.instagram_handle) = '';
