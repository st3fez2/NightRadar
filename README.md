# NightRadar

NightRadar e un prodotto Flutter + Supabase focalizzato su:

- sito web mobile-first per Android e iPhone
- doppio flavor web: `prod` attivo e `demo` read-only
- discovery nightlife ed eventi
- prenotazione ingressi con QR
- area PR per creare eventi e gestire guest list
- export lista via copia-incolla o WhatsApp verso locale o altri PR

## Strategia piattaforma

- priorita assoluta: web ottimizzato per browser mobile
- flavor `prod`: esperienza attiva per utenti e PR
- flavor `demo`: vetrina guidata read-only con account demo
- target secondario: app Android
- iOS nativo: in attesa

## Stack

- Flutter
- Riverpod
- GoRouter
- Supabase Auth + Postgres

## Stato attuale

Il repository contiene un vertical slice funzionante:

1. login / signup
2. landing pubblica con QR sempre visibile, download, share e link live
3. schermata guidata per conferma email quando richiesta dal progetto
4. richiesta account PR separata dal signup utente
5. home utente con eventi e radar
6. dettaglio evento con offerte
7. prenotazione con QR
8. wallet pass
9. dashboard PR con locali partner
10. creazione evento dal lato PR
11. inserimento nominativi manuale
12. export lista via copia-incolla
13. condivisione lista su WhatsApp

## Demo accounts

- `user@nightradar.app`
- `promoter@nightradar.app`
- Password demo: `NightRadar123!`

## URL web

- attivo: `https://st3fez2.github.io/NightRadar/`
- demo: `https://st3fez2.github.io/NightRadar/demo/`

## Comandi utili

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
flutter build apk --debug
powershell -ExecutionPolicy Bypass -File tool/build_web_variants.ps1
```

## Supabase

Workspace locale gia collegato al progetto:

- project ref: `yldrboozmdwqpxrvfvxm`

Le migration principali sono in:

- `supabase/migrations/20260313011359_nightradar_mvp_schema.sql`
- `supabase/migrations/20260313011837_nightradar_demo_seed.sql`
- `supabase/migrations/20260313103000_promoter_event_creation.sql`
- `supabase/migrations/20260313143000_public_feed_anon_access.sql`
- `supabase/migrations/20260313172000_promoter_access_requests.sql`

Per applicare future migration:

```bash
npx supabase db push --yes
```

Per aggiornare Auth hosted con SMTP Gmail e redirect web:

```bash
NIGHTRADAR_GMAIL_APP_PASSWORD=... npx supabase config push --yes
```

## Nota prodotto

NightRadar non include piu una dashboard locale/staff nell app. I locali ricevono i dati finali tramite condivisione esterna della lista.
