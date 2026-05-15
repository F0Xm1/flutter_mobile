# Smart Telemetry System "Чіпідізєль" — Документація

Мобільний додаток на Flutter для моніторингу телеметрії (температура, вологість, тиск) із сенсорів у комерційних приміщеннях у реальному часі.

---

## 1. Технологічний стек

| Компонент | Технологія |
|---|---|
| Mobile | Flutter / Dart |
| State management | BLoC / Cubit (`flutter_bloc`) |
| Database | Supabase (PostgreSQL) |
| Realtime | Supabase Realtime (WebSocket, `postgres_changes`) |
| Auth | Supabase Auth (email/password + Google OAuth) |
| Локальні сповіщення | `flutter_local_notifications` |
| Push (remote) | Firebase Cloud Messaging |
| Charts | `fl_chart` |
| Мережа | `connectivity_plus` |
| Backend | .NET Minimal API + MQTTnet (окремий репозиторій) |
| Env | `flutter_dotenv` |
| DI | `provider` (MultiProvider) |

---

## 2. Архітектура

Проект побудований на поєднанні **Clean Architecture** та **BLoC/Cubit**.

- **Presentation Layer:** Flutter віджети — `BlocBuilder` / `BlocListener` для реакції на стан.
- **Business Logic Layer:** `DashboardCubit`, `EventsCubit`, `AuthCubit`, `TelemetryDataCubit`, `ThresholdCubit`, `ConnectionBloc`.
- **Data Layer:** Supabase репозиторії (`TelemetryRepository`, `ThresholdRepository`, `EventRepository`, `LocationRepository`, `SensorRepository`).

Глобальні інтеграції в `lib/core`:
- `supabase_client.dart` — глобальний геттер `Supabase.instance.client`.
- `auth_guard.dart` — guard на маршруті `/`, перенаправляє на `LoginPage` або `HomePage` залежно від `AuthCubit`.

---

## 3. Структура проекту

```text
lib/
├── core/
│   ├── auth_guard.dart              # Guard LoginPage/HomePage за auth станом
│   └── supabase_client.dart         # Глобальний геттер supabase client
├── data/
│   └── repositories/
│       ├── event_repository.dart
│       ├── location_repository.dart
│       ├── sensor_repository.dart
│       ├── telemetry_repository.dart
│       └── threshold_repository.dart
├── presentation/
│   ├── cubits/
│   │   ├── dashboard_cubit.dart     # DashboardCubit — live дані + lastAlert
│   │   ├── dashboard_state.dart     # DashboardState, DashboardSensorData
│   │   ├── events_cubit.dart        # EventsCubit — журнал порогових подій
│   │   └── events_state.dart        # EventsState
│   └── widgets/
│       ├── sensor_card.dart         # Картка з анімованим значенням і кольором порогу
│       └── backend_status_widget.dart  # Чіп "Онлайн / Немає даних"
├── src/
│   ├── bloc/connection/             # ConnectionBloc — моніторинг мережі
│   ├── cubit/
│   │   ├── auth/                    # AuthCubit + AuthState
│   │   ├── telemetry/               # TelemetryDataCubit + TelemetryDataState
│   │   └── threshold/               # ThresholdCubit + ThresholdState
│   ├── screens/
│   │   ├── auth_page/               # LoginPage, RegisterPage
│   │   ├── events_page/             # EventsPage — журнал подій з Realtime
│   │   ├── home_page/               # HomePage (StatefulWidget), HomeContent (дашборд)
│   │   └── telemetry/               # TelemetryPage
│   ├── services/
│   │   └── push_mess/               # FCMService
│   └── widgets/
│       ├── telemetry_chart_widget.dart
│       ├── threshold_settings_widget.dart
│       └── reusable/
├── firebase_options.dart
└── main.dart
supabase/
├── config.toml
└── migrations/
    ├── 20260514115031_init_tables.sql
    ├── 20260514184751_add_rls_policies.sql
    ├── 20260515125706_thresholds_rls.sql
    ├── 20260515130000_enable_telemetry_realtime.sql
    └── 20260515115706_add_events_table.sql
```

---

## 4. Потоки даних

### 4.1. Дашборд (HomePage)

```
HomePage.initState()
    → DashboardCubit.startWatching()
         → emit DashboardLoading
         → паралельно для 3 сенсорів:
              TelemetryRepository.getLastTelemetry(limit: 1)   ← останнє значення
              ThresholdRepository.getThreshold(sensorId)        ← пороги
         → emit DashboardLoaded
         → TelemetryRepository.watchTelemetry() × 3            ← Realtime підписки
              ↓ кожна нова точка
         → оновити DashboardSensorData відповідного сенсора
         → emit DashboardLoaded
              ↓
    HomeContent → BlocBuilder → _DashboardView
         ├── BackendStatusWidget (Timer 1s, вік останнього запису)
         ├── lastAlert банер (помаранчевий, якщо є остання подія)
         ├── SensorCard × 3 (AnimatedSwitcher, колір порогу)
         └── NavButtons (Телеметрія / Журнал подій / Сенсори)
```

- `DashboardSensorData.isExceeded` — `true` якщо `value > maxThreshold` або `value < minThreshold`.
- `BackendStatusWidget` — `StatefulWidget` з `Timer.periodic(1s)`, рахує `DateTime.now().difference(lastUpdated)`; при > 30 с — помаранчеве попередження.
- `lastAlert` — рядок з останньою пороговою подією; оновлюється при старті і через Realtime підписку на `events`.
- При втраті мережі `HomePage` показує `SnackBar` через `BlocListener<ConnectionBloc>` і закриває його при відновленні.

### 4.2. Realtime телеметрія (TelemetryPage)

```
.NET Simulator → MQTT → .NET Listener → Supabase PostgreSQL
                                               ↓
                              Supabase Realtime WebSocket (postgres_changes)
                                               ↓
                                  TelemetryRepository.watchTelemetry()
                                               ↓
                                  TelemetryDataCubit (stream subscription)
                                        ↓           ↓
                            TelemetryPage         _checkThreshold()
                          TelemetryChartWidget         ↓
                                          FCMService.showLocalNotification()
```

1. `.NET` бекенд отримує MQTT-повідомлення від симулятора і записує у таблицю `telemetry`.
2. `TelemetryRepository.watchTelemetry(sensorId)` відкриває `RealtimeChannel`, підписується на `postgres_changes` з фільтром `sensor_id`.
3. `TelemetryDataCubit.loadAndWatch(sensorId)` завантажує останні 50 точок, потім підписується на stream. Нові точки додаються, зберігаючи максимум 100.
4. При кожному значенні `_checkThreshold()` перевіряє пороги і надсилає локальну нотифікацію (cooldown 30 с).

### 4.3. Завантаження порогів (TelemetryPage)

При відкритті `TelemetryPage` в `initState()`:
1. `TelemetryDataCubit` емітить `TelemetryLoading`.
2. Викликається `getLastTelemetry(sensorId, limit: 50)` — записи реверсуються (старіші — перші).
3. Емітується `TelemetryLoaded(points)`.
4. Паралельно `ThresholdCubit.load(sensorId)` завантажує пороги і передає через `TelemetryDataCubit.updateThreshold(min, max)`.

### 4.4. Перевірка порогів, сповіщення та запис події

```
Realtime point → TelemetryDataCubit
                     ↓
             emit TelemetryLoaded
                     ↓
             _checkThreshold(value)
                ↓           ↓
          cooldown ok?   cooldown active?
                ↓               ↓
        value > max?          skip
        value < min?
                ↓
    FCMService.showLocalNotification()
    _lastNotification = now
    supabase.from('events').insert(...)  ← fire-and-forget (.ignore())
```

- Cooldown — 30 секунд з моменту останньої нотифікації на сенсор.
- Якщо пороги `null` — перевірка не виконується.
- Текст нотифікації: `"28.5°C перевищує максимум 26.0°C"` або `"18.2°C нижче мінімуму 20.0°C"`.
- INSERT в `events` виконується тільки після cooldown-перевірки (разом з нотифікацією). `sensorType` передається через конструктор `TelemetryDataCubit`.

### 4.5. Журнал подій (EventsPage)

```
EventsPage.initState()
    → EventsCubit.loadAndWatch()
         → emit EventsLoading
         → EventRepository.getEvents(limit: 50)   ← останні 50 подій
         → emit EventsLoaded(events)
         → EventRepository.watchEvents()           ← Realtime INSERT підписка
              ↓ нова подія
         → emit EventsLoaded([newEvent, ...events])  ← prepend
              ↓
    ListView з _EventCard
         ├── червона картка: threshold_type == 'max'
         └── синя картка:    threshold_type == 'min'
```

- Час відображається відносно: "щойно / 5 хв тому / 2 год тому / 12.5 14:32".
- Pull-to-refresh → `EventsCubit.refresh()` перезавантажує список.
- Порожній стан: "Порогів ще не було перевищено".

### 4.6. Автентифікація

```
LoginPage → AuthCubit.signIn() → supabase.auth.signInWithPassword()
                                          ↓
                              onAuthStateChange stream
                                          ↓
                                AuthCubit emits AuthAuthenticated
                                          ↓
                                    AuthGuard → HomePage
```

- `AuthCubit` підписується на `supabase.auth.onAuthStateChange` в конструкторі.
- Google OAuth: `supabase.auth.signInWithOAuth(OAuthProvider.google)` відкриває браузер.
- Email-підтвердження вимкнено (`enable_confirmations = false` в Supabase config).

---

## 5. Управління станом

### DashboardCubit (`lib/presentation/cubits/`)

| Стан | Коли |
|---|---|
| `DashboardInitial` | До виклику `startWatching()` |
| `DashboardLoading` | Початкове завантаження з Supabase |
| `DashboardLoaded(temperature, humidity, pressure, lastAlert)` | Дані є; оновлюється при кожному realtime-значенні або новій події |

`startWatching()` паралельно завантажує дані сенсорів, пороги та останню подію з `events`. Підписується на Realtime телеметрії (×3) і Realtime подій (×1). Усі підписки закриваються в `close()`.

`DashboardSensorData` — незмінний value object на один сенсор:

| Поле | Тип | Опис |
|---|---|---|
| `value` | `double?` | Поточне значення (null до першого отримання) |
| `lastUpdated` | `DateTime?` | Час запису (UTC → local) |
| `minThreshold` | `double?` | Мінімальний поріг або null |
| `maxThreshold` | `double?` | Максимальний поріг або null |
| `isExceeded` | `bool` | `true` якщо value за межами порогів |

### AuthCubit (`lib/src/cubit/auth/`)

| Стан | Коли |
|---|---|
| `AuthInitial` | До першої перевірки сесії |
| `AuthLoading` | Під час sign-in / sign-up / sign-out |
| `AuthAuthenticated` | Supabase сесія активна |
| `AuthUnauthenticated` | Немає сесії або після виходу |
| `AuthError(message)` | Помилка Supabase Auth |

### TelemetryDataCubit (`lib/src/cubit/telemetry/`)

| Стан | Коли |
|---|---|
| `TelemetryInitial` | `SENSOR_ID_*` не задано у `.env` |
| `TelemetryLoading` | Початкове завантаження |
| `TelemetryLoaded(points)` | Дані є, список оновлюється realtime |
| `TelemetryError(message)` | Помилка мережі або Supabase |

Приймає `sensorType` у конструкторі (`'temperature'` | `'humidity'` | `'pressure'`) — потрібен для INSERT в `events`.
Внутрішній стан (не в emit): `_minThreshold`, `_maxThreshold`, `_lastNotification`.

### EventsCubit (`lib/presentation/cubits/`)

| Стан | Коли |
|---|---|
| `EventsInitial` | До виклику `loadAndWatch()` |
| `EventsLoading` | Початкове завантаження |
| `EventsLoaded(events)` | Список подій; нові prepend-яться через Realtime |
| `EventsError(message)` | Помилка Supabase |

### ThresholdCubit (`lib/src/cubit/threshold/`)

| Стан | Коли |
|---|---|
| `ThresholdInitial` | До виклику `load()` |
| `ThresholdLoading` | Завантаження або збереження |
| `ThresholdLoaded(min, max)` | Пороги завантажені (min/max можуть бути null) |
| `ThresholdError(message)` | Помилка Supabase |

### ConnectionBloc (`lib/src/bloc/connection/`)

Глобальний блок, що моніторить мережу через `connectivity_plus`. `HomePage` слухає через `BlocListener` — показує `SnackBar` при `ConnectionDisconnected`, закриває при `ConnectionConnected`.

---

## 6. Репозиторії (`lib/data/repositories/`)

### TelemetryRepository

```dart
// Останні N записів (за замовчуванням 50), впорядковані desc
Future<List<Map<String, dynamic>>> getLastTelemetry(String sensorId, {int limit = 50})

// Realtime stream нових записів через Supabase RealtimeChannel
Stream<Map<String, dynamic>> watchTelemetry(String sensorId)
```

`watchTelemetry` — `StreamController`-based stream. При підписці відкриває `RealtimeChannel`. При скасуванні — видаляє канал через `supabase.removeChannel()`.

### ThresholdRepository

```dart
// Повертає null якщо пороги не встановлені
Future<Map<String, dynamic>?> getThreshold(String sensorId)

// Upsert по sensor_id
Future<void> upsertThreshold(String sensorId, double? min, double? max)
```

### EventRepository

```dart
// Останні N подій, впорядковані desc (за triggered_at)
Future<List<Map<String, dynamic>>> getEvents({int limit = 50})

// Realtime stream нових INSERT-подій
Stream<Map<String, dynamic>> watchEvents()
```

### LocationRepository / SensorRepository

Використовуються для читання даних про приміщення та сенсори (тільки `SELECT`).

---

## 7. База даних (Supabase PostgreSQL)

### Схема

```sql
locations   (id uuid PK, name text, address text, created_at timestamptz)
sensors     (id uuid PK, location_id uuid FK→locations, name text, type text, unit text, created_at timestamptz)
telemetry   (id bigint IDENTITY PK, sensor_id uuid FK→sensors, value numeric, recorded_at timestamptz)
thresholds  (id uuid PK, sensor_id uuid FK→sensors UNIQUE, min_value numeric, max_value numeric)
events      (id bigint IDENTITY PK, sensor_id uuid FK→sensors ON DELETE CASCADE,
             sensor_type text, value numeric, threshold_type text,
             threshold_value numeric, triggered_at timestamptz DEFAULT now())
```

Індекси: `telemetry_sensor_time_idx ON telemetry(sensor_id, recorded_at DESC)`, `events_triggered_at_idx ON events(triggered_at DESC)`.

`thresholds.sensor_id` — унікальний constraint, upsert через `onConflict: 'sensor_id'`.

### RLS

| Таблиця | SELECT | INSERT | UPDATE |
|---|---|---|---|
| locations | authenticated | — | — |
| sensors | authenticated | — | — |
| telemetry | authenticated | — | — |
| thresholds | authenticated | authenticated | authenticated |
| events | authenticated | authenticated | — |

Запис у `telemetry` виконує тільки .NET бекенд через `service_role` ключ. Запис у `events` виконує Flutter-клієнт при спрацюванні порогу.

### Realtime

Таблиці `telemetry` та `events` включені в publication `supabase_realtime`:
```sql
alter publication supabase_realtime add table telemetry;
alter publication supabase_realtime add table events;
```
Без цього `postgres_changes` WebSocket events не надходять до клієнта.

### Сенсори (UUID)

| Тип | UUID | Одиниця |
|---|---|---|
| temperature | `08769695-abd6-48de-a5b6-f2b9f3e2dc74` | °C |
| humidity | `8f9c6a83-f16b-4ffa-ae5b-5495271f16df` | % |
| pressure | `237d9612-a86d-437e-a118-d0bf5bfc6833` | hPa |

UUID задаються у `.env` через `SENSOR_ID_TEMPERATURE`, `SENSOR_ID_HUMIDITY`, `SENSOR_ID_PRESSURE`.

---

## 8. Графіки (`lib/src/widgets/telemetry_chart_widget.dart`)

`TelemetryChartWidget` використовує `fl_chart` для побудови лінійного графіка:

- **X вісь:** порядковий індекс точки.
- **Y вісь:** значення + одиниця виміру; діапазон розширюється якщо пороги виходять за межі даних.
- **Колір лінії:** `°C` → червоний, `%` → синій, `hPa` → зелений.
- **Відображає:** останні 50 точок.
- **Анімація:** 300 мс при оновленні.
- **Tooltip:** значення + одиниця при дотику.
- **Порогові лінії:** горизонтальні пунктирні лінії через `ExtraLinesData` — червона (max), синя (min).

---

## 9. Push-повідомлення та локальні нотифікації

`FCMService.init()` викликається при запуску:
- Запитує дозвіл на нотифікації.
- Явно створює Android notification channel `threshold_alerts` (Importance.high).
- Налаштовує обробники foreground/background FCM-повідомлень.
- Firebase використовується **тільки для FCM** — не для Auth.

`FCMService.showLocalNotification(title, body)` — показує локальну нотифікацію через `flutter_local_notifications`.

---

## 10. Маршрути

| Маршрут | Сторінка |
|---|---|
| `/` | `AuthGuard` |
| `/login` | `LoginPage` |
| `/register` | `RegisterPage` |
| `/home` | `HomePage` (дашборд) |
| `/telemetry` | `TelemetryPage` |
| `/events` | `EventsPage` — журнал порогових подій |
| `/sensors` | Сенсори (заглушка) |

---

## 11. Налаштування та запуск

### Передумови

- Flutter SDK ^3.2.6
- Supabase CLI (`brew install supabase/tap/supabase`)

### Клонування та залежності

```bash
git clone <repo>
cd mobile_lab
flutter pub get
```

### Конфігурація `.env`

Створіть `.env` у корені проекту (не комітити):

```env
SUPABASE_URL=https://unjpmqtykfsywbvnrnry.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SENSOR_ID_TEMPERATURE=08769695-abd6-48de-a5b6-f2b9f3e2dc74
SENSOR_ID_HUMIDITY=8f9c6a83-f16b-4ffa-ae5b-5495271f16df
SENSOR_ID_PRESSURE=237d9612-a86d-437e-a118-d0bf5bfc6833
```

### Supabase міграції

```bash
supabase link --project-ref unjpmqtykfsywbvnrnry
supabase db push
```

### Firebase

Файли конфігурації в репозиторії:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

### Запуск

```bash
flutter run
```

---

## 12. Команди розробника

```bash
flutter run           # Запуск
flutter analyze       # Аналіз коду
flutter pub get       # Залежності
supabase db push      # Застосувати міграції
supabase config push  # Синхронізувати auth конфіг
```

---

## 13. Що НЕ робити

- Не комітити `.env`
- Не використовувати `service_role` ключ у Flutter — він для .NET бекенду
- Не хардкодити IP-адреси, URL або ключі
- Не використовувати Firebase Auth — тільки Supabase Auth
- Не класти бізнес-логіку у віджети — тільки у Cubit-и
- Не використовувати `print()` — тільки `log()` з `dart:developer`
- Не використовувати SharedPreferences для auth токенів
