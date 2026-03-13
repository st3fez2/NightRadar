insert into public.venues (
  id,
  name,
  slug,
  description,
  address_line,
  city,
  latitude,
  longitude,
  capacity,
  categories,
  dress_code,
  price_band
)
values
  (
    '11111111-1111-1111-1111-111111111111',
    'Volt Club Milano',
    'volt-club-milano',
    'Club orientato a serate house e commerciale con gestione liste e tavoli.',
    'Via della Notte 21',
    'Milano',
    45.464200,
    9.190000,
    650,
    array['club', 'house', 'commerciale'],
    'smart casual',
    'mid'
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'Warehouse District',
    'warehouse-district',
    'Venue piu spinto su techno e guest DJ, adatto a testare il radar.',
    'Viale Industria 8',
    'Milano',
    45.489000,
    9.210000,
    900,
    array['club', 'techno', 'live'],
    'dark minimal',
    'mid-high'
  )
on conflict (id) do nothing;

insert into public.events (
  id,
  venue_id,
  title,
  event_date,
  starts_at,
  ends_at,
  description,
  lineup,
  music_tags,
  status,
  entry_policy,
  is_public,
  cover_image_url
)
values
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'Friday Signal',
    current_date,
    timezone('utc', now()) + interval '4 hours',
    timezone('utc', now()) + interval '10 hours',
    'Serata pilota NightRadar con focus su liste e ingressi rapidi.',
    'Resident set + special guest',
    array['house', 'commerciale'],
    'published',
    'Ingresso in lista fino all''01:00, tavoli su richiesta.',
    true,
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80'
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '22222222-2222-2222-2222-222222222222',
    'Deep Frequency',
    current_date + 1,
    timezone('utc', now()) + interval '28 hours',
    timezone('utc', now()) + interval '35 hours',
    'Evento demo per radar attivo e prenotazioni tavolo.',
    'Warehouse residents',
    array['techno', 'live'],
    'published',
    'Biglietto o accredito PR fino alle 00:30.',
    true,
    'https://images.unsplash.com/photo-1571266028243-d220c9d94a62?auto=format&fit=crop&w=1200&q=80'
  )
on conflict (id) do nothing;

insert into public.event_offers (
  id,
  event_id,
  type,
  title,
  description,
  price,
  capacity_total,
  valid_until,
  conditions,
  is_active
)
values
  (
    'aaaa1111-aaaa-1111-aaaa-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'guest_list_reduced',
    'Lista ridotta',
    'Ingresso ridotto con accesso prioritario.',
    15,
    180,
    timezone('utc', now()) + interval '6 hours',
    'Valido fino all''01:00',
    true
  ),
  (
    'bbbb1111-bbbb-1111-bbbb-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'vip_pass',
    'Pass VIP',
    'Accesso con area dedicata e drink incluso.',
    35,
    40,
    timezone('utc', now()) + interval '5 hours',
    'Quantita limitata',
    true
  ),
  (
    'cccc1111-cccc-1111-cccc-111111111111',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'ticket',
    'Ticket early entry',
    'Ingresso garantito entro mezzanotte e trenta.',
    20,
    220,
    timezone('utc', now()) + interval '29 hours',
    'Mostrare QR al desk',
    true
  )
on conflict (id) do nothing;

insert into public.radar_signals (
  event_id,
  venue_id,
  source,
  signal_type,
  signal_value,
  weight,
  note
)
values
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'venue_staff',
    'crowd',
    3,
    1.5,
    'Affluenza in salita dalle 23:30'
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '22222222-2222-2222-2222-222222222222',
    'venue_staff',
    'booking_velocity',
    4,
    1.2,
    'Molte richieste nelle ultime ore'
  )
on conflict do nothing;
