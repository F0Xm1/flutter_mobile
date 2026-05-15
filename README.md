# Chipidiezel — Smart Telemetry System

Flutter mobile application for real-time monitoring of temperature, humidity and pressure sensors across commercial premises. Data flows from a .NET simulator via MQTT into Supabase and is streamed live to the app over WebSocket.

---

## Features

- **Live dashboard** — sensor values update in real time via Supabase Realtime
- **Multi-location support** — switch between locations from the dashboard AppBar
- **Telemetry charts** — fl_chart line graphs with threshold lines for each sensor
- **Threshold alerts** — configurable min/max per sensor; local notification on breach with 30 s cooldown; event written to DB
- **Events log** — real-time feed of threshold breaches with pull-to-refresh
- **Sensors management** — full CRUD for locations and sensors (swipe-to-delete, bottom sheets)
- **CSV export** — export telemetry for any date range; share sheet opens automatically
- **Offline cache** — last known values per location served from SharedPreferences when network is lost; yellow banner indicates stale data
- **Auth** — email/password and Google OAuth via Supabase Auth
- **Push notifications** — Firebase Cloud Messaging

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter / Dart |
| State | BLoC / Cubit (`flutter_bloc`) |
| Database | Supabase (PostgreSQL) |
| Realtime | Supabase Realtime (WebSocket, `postgres_changes`) |
| Auth | Supabase Auth |
| Push | Firebase Cloud Messaging |
| Local notifications | `flutter_local_notifications` |
| Charts | `fl_chart` |
| CSV export | `csv` + `share_plus` + `path_provider` |
| Offline cache | `shared_preferences` |
| Connectivity | `connectivity_plus` |
| Backend | .NET Minimal API + MQTTnet (separate repo) |

---

## Architecture

```
Presentation Layer
  └── BlocBuilder / BlocListener widgets
        └── DashboardCubit, EventsCubit, SensorsCubit,
            TelemetryDataCubit, ThresholdCubit, AuthCubit,
            ConnectionBloc

Data Layer
  └── Repositories (Supabase queries + Realtime streams)
        └── TelemetryRepository, ThresholdRepository,
            EventRepository, LocationRepository,
            SensorRepository, ExportRepository

Services
  └── ExportService (CSV generation + share)
  └── CacheService (SharedPreferences offline store)
  └── FCMService (push notifications)
```

Clean Architecture with strict separation: widgets hold no business logic, cubits hold no Supabase calls, repositories hold no state.

---

## Project Structure

```
lib/
├── core/
│   ├── auth_guard.dart              # Route guard (/ → login or home)
│   └── supabase_client.dart         # Global Supabase.instance.client getter
├── data/repositories/               # All Supabase I/O
│   ├── telemetry_repository.dart    # getLastTelemetry, watchTelemetry (stream)
│   ├── export_repository.dart       # getTelemetryRange (CSV export)
│   ├── threshold_repository.dart
│   ├── event_repository.dart
│   ├── location_repository.dart
│   └── sensor_repository.dart
├── presentation/
│   ├── cubits/
│   │   ├── dashboard_cubit.dart     # Live dashboard + offline cache logic
│   │   ├── events_cubit.dart
│   │   └── sensors_cubit.dart
│   └── widgets/
│       ├── sensor_card.dart
│       └── backend_status_widget.dart
└── src/
    ├── bloc/connection/             # ConnectionBloc (connectivity_plus)
    ├── cubit/auth|telemetry|threshold/
    ├── screens/
    │   ├── home_page/               # Dashboard + offline banner
    │   ├── telemetry/               # Charts + CSV export bottom sheet
    │   ├── events_page/
    │   ├── sensors_page/
    │   └── auth_page/
    └── services/
        ├── export_service.dart      # CSV build → temp file → share
        ├── cache_service.dart       # SharedPreferences per-location cache
        └── push_mess/fcm_service.dart
```

---

## Database Schema

```sql
locations  (id uuid PK, name text, address text, created_at timestamptz)
sensors    (id uuid PK, location_id uuid FK, name text, type text, unit text)
telemetry  (id bigint PK, sensor_id uuid FK, value numeric, recorded_at timestamptz)
thresholds (id uuid PK, sensor_id uuid FK UNIQUE, min_value numeric, max_value numeric)
events     (id bigint PK, sensor_id uuid FK, sensor_type text, value numeric,
            threshold_type text, threshold_value numeric, triggered_at timestamptz)
```

Tables `telemetry` and `events` are included in the `supabase_realtime` publication.
Row-Level Security is enabled on all tables; `telemetry` writes go through the .NET backend using the `service_role` key.

---

## Quick Start

### Prerequisites

- Flutter SDK `^3.2.6`
- Supabase CLI (`brew install supabase/tap/supabase`)
- Firebase project with FCM enabled

### 1. Clone and install

```bash
git clone https://github.com/F0Xm1/smart_station.git
cd smart_station
flutter pub get
```

### 2. Create `.env`

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

Sensor IDs are loaded dynamically from the `sensors` table — no hardcoding needed.

### 3. Apply migrations

```bash
supabase link --project-ref <project-ref>
supabase db push
```

### 4. Run

```bash
flutter run
```

---

## Offline Mode

When the device loses connectivity, `DashboardCubit` detects the `ConnectionDisconnected` event from `ConnectionBloc` and serves the last cached values from `SharedPreferences`. A yellow banner appears at the top of the dashboard. On reconnect, a full reload is triggered automatically and the banner disappears.

---

## CSV Export

Open the Telemetry screen, tap the download icon in the AppBar, pick a date range, and press **Export**. The app queries Supabase for all sensor readings in the selected range, builds a UTF-8 CSV file:

```
Час,Тип,Значення,Одиниця
2026-05-15 14:32:00,Температура,22.5,°C
2026-05-15 14:32:00,Вологість,48.3,%
```

The file is saved to the device temp directory and shared via the system share sheet. Export is disabled when offline.

---

## Developer Commands

```bash
flutter run           # Run app
flutter analyze       # Lint (run before every commit)
flutter pub get       # Install dependencies
supabase db push      # Apply migrations
supabase migration new <name>   # New migration file
```

---

## Documentation

- [DOCUMENTATION.md](./DOCUMENTATION.md) — data flows, state machine, repositories, RLS, Realtime setup
