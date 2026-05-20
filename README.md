# Чіпідізєль — Система моніторингу телеметрії

Flutter-додаток для моніторингу температури, вологості та тиску з сенсорів у комерційних приміщеннях у реальному часі. Дані надходять від .NET-симулятора через MQTT у Supabase і транслюються в додаток через WebSocket.

---

## Функціонал

- **Живий дашборд** — значення сенсорів оновлюються в реальному часі через Supabase Realtime; pull-to-refresh
- **Мультитенантність** — кожен користувач бачить лише свої локації та сенсори (RLS через `user_id`)
- **Онбординг** — 3-кроковий екран для нових користувачів з можливістю створити першу локацію
- **Підтримка кількох локацій** — перемикання між локаціями прямо з AppBar дашборду; дашборд оновлюється автоматично після повернення з екрану сенсорів
- **Розумні картки сенсорів** — відображаються лише картки для існуючих типів сенсорів; порожній стан з підказкою якщо сенсорів ще немає
- **Графіки телеметрії** — лінійні графіки fl_chart з лініями порогів; вкладки за назвою сенсора (наприклад "Кухня (°C)")
- **Порогові сповіщення** — налаштовувані мін/макс для кожного сенсора; локальне сповіщення при перевищенні з cooldown 30 с
- **Журнал подій** — live-стрічка порогових перевищень з pull-to-refresh
- **Управління сенсорами** — повний CRUD для локацій і сенсорів (swipe-to-delete, bottom sheets)
- **Профіль** — статистика системи (кількість локацій, сенсорів, подій за сьогодні)
- **Експорт Excel** — вивантаження телеметрії за будь-який діапазон дат у `.xlsx`-файл; зберігається у папку Завантаження
- **Офлайн-кеш** — останні відомі значення зберігаються в SharedPreferences; банер при відсутності мережі
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
| Експорт Excel | `excel` + `path_provider` |
| Офлайн-кеш | `shared_preferences` |
| Моніторинг мережі | `connectivity_plus` |
| Бекенд | .NET Minimal API + MQTTnet (окремий репозиторій) |

---

## Архітектура

```
Presentation Layer
  └── BlocBuilder / BlocListener віджети
        └── DashboardCubit, EventsCubit, SensorsCubit,
            TelemetryDataCubit, ThresholdCubit,
            AuthCubit, ProfileCubit, ConnectionBloc

Data Layer
  └── Репозиторії (Supabase-запити + Realtime-стріми)
        └── TelemetryRepository, ThresholdRepository,
            EventRepository, LocationRepository,
            SensorRepository, ExportRepository

Services
  └── ExportService  — формування .xlsx → Downloads
  └── CacheService   — офлайн-сховище (SharedPreferences)
  └── FCMService     — push-сповіщення
```

Чиста архітектура з суворим розділенням: віджети не містять бізнес-логіки, кубіти не звертаються до Supabase напряму, репозиторії не зберігають стан.

---

## Структура проекту

```
lib/
├── core/
│   ├── auth_guard.dart              # Guard: / → /onboarding або /home
│   └── supabase_client.dart         # Глобальний геттер Supabase.instance.client
├── data/repositories/               # Весь Supabase I/O
│   ├── telemetry_repository.dart    # getLastTelemetry, watchTelemetry (stream)
│   ├── export_repository.dart       # getTelemetryRange (для Excel-експорту)
│   ├── threshold_repository.dart
│   ├── event_repository.dart        # getEvents, watchEvents, getTodayEventsCount
│   ├── location_repository.dart     # user_id-scoped CRUD
│   └── sensor_repository.dart
├── presentation/
│   ├── cubits/
│   │   ├── dashboard_cubit.dart     # Живий дашборд + офлайн-кеш + reload()
│   │   ├── events_cubit.dart
│   │   └── sensors_cubit.dart
│   └── widgets/
│       ├── sensor_card.dart
│       └── backend_status_widget.dart
└── src/
    ├── bloc/connection/             # ConnectionBloc (connectivity_plus)
    ├── cubit/
    │   ├── auth/                    # AuthCubit + AuthState
    │   ├── profile/                 # ProfileCubit — статистика системи
    │   ├── telemetry/               # TelemetryDataCubit
    │   └── threshold/               # ThresholdCubit
    ├── screens/
    │   ├── home_page/               # Дашборд + pull-to-refresh + empty states
    │   ├── onboarding_page/         # 3-кроковий онбординг для нових користувачів
    │   ├── profile_page/            # Профіль + статистика + вихід
    │   ├── telemetry/               # Графіки + bottom sheet Excel-експорту
    │   ├── events_page/
    │   ├── sensors_page/
    │   └── auth_page/
    └── services/
        ├── export_service.dart      # Формування .xlsx → Downloads
        ├── cache_service.dart       # SharedPreferences кеш по локації
        └── push_mess/fcm_service.dart
```

---

## Схема бази даних

```sql
locations  (id uuid PK, name text, address text,
            user_id uuid FK→auth.users ON DELETE CASCADE,
            created_at timestamptz)
sensors    (id uuid PK, location_id uuid FK, name text, type text, unit text)
telemetry  (id bigint PK, sensor_id uuid FK, value numeric, recorded_at timestamptz)
thresholds (id uuid PK, sensor_id uuid FK UNIQUE, min_value numeric, max_value numeric)
events     (id bigint PK, sensor_id uuid FK, sensor_type text, value numeric,
            threshold_type text, threshold_value numeric, triggered_at timestamptz)
```

Таблиці `telemetry` та `events` включені в publication `supabase_realtime`.
RLS увімкнено на всіх таблицях — кожен користувач бачить лише свої дані через ланцюжок `locations.user_id = auth.uid()`. Запис у `telemetry` виконує тільки .NET-бекенд через `service_role`-ключ.

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

### 3. Міграції Supabase

```bash
supabase link --project-ref <project-ref>
supabase db push
```

### 4. Google OAuth (опціонально)

1. Google Cloud Console → OAuth 2.0 Client ID (Web) → Authorized redirect URIs:
   `https://<project-ref>.supabase.co/auth/v1/callback`
2. Supabase Dashboard → Authentication → Providers → Google → увімкнути.
3. Supabase Dashboard → Authentication → URL Configuration → Redirect URLs:
   `com.example.test1://login-callback`

### 5. Запуск

```bash
flutter run
```

---

## Офлайн-режим

При втраті мережі `DashboardCubit` отримує подію від `ConnectionBloc` і відображає останні закешовані значення з `SharedPreferences`. Банер у верхній частині дашборду сигналізує про застарілі дані. При відновленні мережі автоматично виконується повне перезавантаження.

---

## Експорт Excel

На екрані телеметрії натисніть іконку завантаження в AppBar, оберіть діапазон дат і натисніть **Зберегти .xlsx**. Додаток формує Excel-файл з колонками:

```
Час | Сенсор | Тип | Значення | Одиниця
2026-05-15 14:32:00 | Кухня | Температура | 22.5 | °C
```

Файл зберігається у папку **Завантаження** (`/storage/emulated/0/Download/`) і відображається снекбар з назвою файлу. Формат `.xlsx` нативно підтримує кирилицю. Експорт недоступний у офлайн-режимі.

---

## Команди розробника

```bash
flutter run                       # Запуск
flutter analyze                   # Аналіз коду (перед кожним комітом)
flutter pub get                   # Встановити залежності
supabase db push                  # Застосувати міграції
supabase migration new <назва>    # Новий файл міграції
```

---

## Документація

- [DOCUMENTATION.md](./DOCUMENTATION.md) — потоки даних, стани кубітів, репозиторії, RLS, налаштування Realtime
