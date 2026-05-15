# Чіпідізєль — Система моніторингу телеметрії

Flutter-додаток для моніторингу температури, вологості та тиску з сенсорів у комерційних приміщеннях у реальному часі. Дані надходять від .NET-симулятора через MQTT у Supabase і транслюються в додаток через WebSocket.

---

## Функціонал

- **Живий дашборд** — значення сенсорів оновлюються в реальному часі через Supabase Realtime
- **Підтримка кількох локацій** — перемикання між локаціями прямо з AppBar дашборду
- **Графіки телеметрії** — лінійні графіки fl_chart з лініями порогів для кожного сенсора
- **Порогові сповіщення** — налаштовувані мін/макс для кожного сенсора; локальне сповіщення при перевищенні з cooldown 30 с; подія записується у БД
- **Журнал подій** — live-стрічка порогових перевищень з pull-to-refresh
- **Управління сенсорами** — повний CRUD для локацій і сенсорів (swipe-to-delete, bottom sheets)
- **Експорт CSV** — вивантаження телеметрії за будь-який діапазон дат через системний share sheet
- **Офлайн-кеш** — останні відомі значення по локації зберігаються в SharedPreferences; жовтий банер показується при відсутності мережі
- **Авторизація** — email/пароль та Google OAuth через Supabase Auth
- **Push-сповіщення** — Firebase Cloud Messaging

---

## Технологічний стек

| Шар | Технологія |
|---|---|
| Мобільний додаток | Flutter / Dart |
| Управління станом | BLoC / Cubit (`flutter_bloc`) |
| База даних | Supabase (PostgreSQL) |
| Realtime | Supabase Realtime (WebSocket, `postgres_changes`) |
| Авторизація | Supabase Auth |
| Push-сповіщення | Firebase Cloud Messaging |
| Локальні сповіщення | `flutter_local_notifications` |
| Графіки | `fl_chart` |
| Експорт CSV | `csv` + `share_plus` + `path_provider` |
| Офлайн-кеш | `shared_preferences` |
| Моніторинг мережі | `connectivity_plus` |
| Бекенд | .NET Minimal API + MQTTnet (окремий репозиторій) |

---

## Архітектура

```
Presentation Layer
  └── BlocBuilder / BlocListener віджети
        └── DashboardCubit, EventsCubit, SensorsCubit,
            TelemetryDataCubit, ThresholdCubit, AuthCubit,
            ConnectionBloc

Data Layer
  └── Репозиторії (Supabase-запити + Realtime-стріми)
        └── TelemetryRepository, ThresholdRepository,
            EventRepository, LocationRepository,
            SensorRepository, ExportRepository

Services
  └── ExportService  — формування CSV + share
  └── CacheService   — офлайн-сховище (SharedPreferences)
  └── FCMService     — push-сповіщення
```

Чиста архітектура з суворим розділенням: віджети не містять бізнес-логіки, кубіти не звертаються до Supabase напряму, репозиторії не зберігають стан.

---

## Структура проекту

```
lib/
├── core/
│   ├── auth_guard.dart              # Route guard (/ → логін або дашборд)
│   └── supabase_client.dart         # Глобальний геттер Supabase.instance.client
├── data/repositories/               # Весь Supabase I/O
│   ├── telemetry_repository.dart    # getLastTelemetry, watchTelemetry (stream)
│   ├── export_repository.dart       # getTelemetryRange (для CSV-експорту)
│   ├── threshold_repository.dart
│   ├── event_repository.dart
│   ├── location_repository.dart
│   └── sensor_repository.dart
├── presentation/
│   ├── cubits/
│   │   ├── dashboard_cubit.dart     # Живий дашборд + офлайн-кеш
│   │   ├── events_cubit.dart
│   │   └── sensors_cubit.dart
│   └── widgets/
│       ├── sensor_card.dart
│       └── backend_status_widget.dart
└── src/
    ├── bloc/connection/             # ConnectionBloc (connectivity_plus)
    ├── cubit/auth|telemetry|threshold/
    ├── screens/
    │   ├── home_page/               # Дашборд + офлайн-банер
    │   ├── telemetry/               # Графіки + bottom sheet експорту CSV
    │   ├── events_page/
    │   ├── sensors_page/
    │   └── auth_page/
    └── services/
        ├── export_service.dart      # Формування CSV → temp-файл → share
        ├── cache_service.dart       # SharedPreferences кеш по локації
        └── push_mess/fcm_service.dart
```

---

## Схема бази даних

```sql
locations  (id uuid PK, name text, address text, created_at timestamptz)
sensors    (id uuid PK, location_id uuid FK, name text, type text, unit text)
telemetry  (id bigint PK, sensor_id uuid FK, value numeric, recorded_at timestamptz)
thresholds (id uuid PK, sensor_id uuid FK UNIQUE, min_value numeric, max_value numeric)
events     (id bigint PK, sensor_id uuid FK, sensor_type text, value numeric,
            threshold_type text, threshold_value numeric, triggered_at timestamptz)
```

Таблиці `telemetry` та `events` включені в publication `supabase_realtime`.
RLS увімкнено на всіх таблицях; запис у `telemetry` виконує тільки .NET-бекенд через `service_role`-ключ.

---

## Швидкий старт

### Передумови

- Flutter SDK `^3.2.6`
- Supabase CLI (`brew install supabase/tap/supabase`)
- Firebase-проект з увімкненим FCM

### 1. Клонування та залежності

```bash
git clone https://github.com/F0Xm1/smart_station.git
cd smart_station
flutter pub get
```

### 2. Файл `.env`

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

ID сенсорів у `.env` не потрібні — завантажуються динамічно з таблиці `sensors`.

### 3. Міграції Supabase

```bash
supabase link --project-ref <project-ref>
supabase db push
```

### 4. Запуск

```bash
flutter run
```

---

## Офлайн-режим

При втраті мережі `DashboardCubit` отримує подію `ConnectionDisconnected` від `ConnectionBloc` і відображає останні закешовані значення з `SharedPreferences`. Жовтий банер у верхній частині дашборду сигналізує про застарілі дані. При відновленні мережі автоматично виконується повне перезавантаження і банер зникає.

---

## Експорт CSV

На екрані телеметрії натисніть іконку завантаження в AppBar, оберіть діапазон дат і натисніть **Експортувати**. Додаток запитує всі показники сенсорів за вибраний період, формує UTF-8 CSV-файл:

```
Час,Тип,Значення,Одиниця
2026-05-15 14:32:00,Температура,22.5,°C
2026-05-15 14:32:00,Вологість,48.3,%
```

Файл зберігається у тимчасову директорію пристрою і відкривається системний share sheet. Експорт недоступний у офлайн-режимі.

---

## Команди розробника

```bash
flutter run                       # Запуск
flutter analyze                   # Аналіз коду (запускати перед кожним комітом)
flutter pub get                   # Встановити залежності
supabase db push                  # Застосувати міграції
supabase migration new <назва>    # Новий файл міграції
```

---

## Документація

- [DOCUMENTATION.md](./DOCUMENTATION.md) — потоки даних, стани кубітів, репозиторії, RLS, налаштування Realtime
