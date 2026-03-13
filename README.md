# NightRadar

NightRadar e un prodotto Flutter + Supabase focalizzato su:

- sito web mobile-first per Android e iPhone
- discovery nightlife ed eventi
- prenotazione ingressi con QR
- area PR per creare eventi e gestire guest list
- export lista via copia-incolla o WhatsApp verso locale o altri PR

## Strategia piattaforma

- priorita assoluta: web ottimizzato per browser mobile
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
2. home utente con eventi e radar
3. dettaglio evento con offerte
4. prenotazione con QR
5. wallet pass
6. dashboard PR con locali partner
7. creazione evento dal lato PR
8. inserimento nominativi manuale
9. export lista via copia-incolla
10. condivisione lista su WhatsApp

## Demo accounts

- `user@nightradar.app`
- `promoter@nightradar.app`
- Password demo: `NightRadar123!`

## Comandi utili

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## Supabase

Workspace locale gia collegato al progetto:

- project ref: `yldrboozmdwqpxrvfvxm`

Le migration principali sono in:

- `supabase/migrations/20260313011359_nightradar_mvp_schema.sql`
- `supabase/migrations/20260313011837_nightradar_demo_seed.sql`
- `supabase/migrations/20260313103000_promoter_event_creation.sql`

Per applicare future migration:

```bash
npx supabase db push --yes
```

## Nota prodotto

NightRadar non include piu una dashboard locale/staff nell app. I locali ricevono i dati finali tramite condivisione esterna della lista.
