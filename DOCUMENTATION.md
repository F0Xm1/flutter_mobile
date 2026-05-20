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
| Офлайн-кеш | `shared_preferences` |
| Експорт Excel | `excel`, `path_provider` |
| Backend | .NET Minimal API + MQTTnet (окремий репозиторій) |
| Env | `flutter_dotenv` |
| DI | `provider` (MultiProvider) |

---

## 2. Архітектура

Проект побудований на поєднанні **Clean Architecture** та **BLoC/Cubit**.

- **Presentation Layer:** Flutter віджети — `BlocBuilder` / `BlocListener` для реакції на стан.
- **Business Logic Layer:** `DashboardCubit`, `EventsCubit`, `AuthCubit`, `TelemetryDataCubit`, `ThresholdCubit`, `SensorsCubit`, `ProfileCubit`, `ConnectionBloc`.
- **Data Layer:** Supabase репозиторії (`TelemetryRepository`, `ThresholdRepository`, `EventRepository`, `LocationRepository`, `SensorRepository`, `ExportRepository`).

Глобальні інтеграції в `lib/core`:
- `supabase_client.dart` — глобальний геттер `Supabase.instance.client`.
- `auth_guard.dart` — `StatefulWidget` на маршруті `/`; перевіряє стан `AuthCubit` та кількість локацій користувача, перенаправляє на `OnboardingPage` (якщо локацій немає) або `HomePage`.

---

## 3. Структура проекту

```text
lib/
├── core/
│   ├── auth_guard.dart              # Guard: /onboarding або /home залежно від локацій
│   └── supabase_client.dart         # Глобальний геттер supabase client
├── data/
│   └── repositories/
│       ├── event_repository.dart
│       ├── export_repository.dart       # Телеметрія за діапазон дат (Excel-експорт)
│       ├── location_repository.dart
│       ├── sensor_repository.dart
│       ├── telemetry_repository.dart
│       └── threshold_repository.dart
├── presentation/
│   ├── cubits/
│   │   ├── dashboard_cubit.dart     # DashboardCubit — live дані + lastAlert
│   │   ├── dashboard_state.dart     # DashboardState, DashboardSensorData
│   │   ├── events_cubit.dart        # EventsCubit — журнал порогових подій
│   │   ├── events_state.dart        # EventsState
│   │   ├── sensors_cubit.dart       # SensorsCubit — управління локаціями і сенсорами
│   │   └── sensors_state.dart       # SensorsState
│   └── widgets/
│       ├── sensor_card.dart         # Картка з анімованим значенням і кольором порогу
│       └── backend_status_widget.dart  # Чіп "Онлайн / Немає даних"
├── src/
│   ├── bloc/connection/             # ConnectionBloc — моніторинг мережі
│   ├── cubit/
│   │   ├── auth/                    # AuthCubit + AuthState
│   │   ├── profile/                 # ProfileCubit + ProfileState (статистика системи)
│   │   ├── telemetry/               # TelemetryDataCubit + TelemetryDataState
│   │   └── threshold/               # ThresholdCubit + ThresholdState
│   ├── screens/
│   │   ├── auth_page/               # LoginPage, RegisterPage
│   │   ├── events_page/             # EventsPage — журнал подій з Realtime
│   │   ├── home_page/               # HomePage (StatefulWidget), HomeContent (дашборд)
│   │   ├── onboarding_page/         # OnboardingPage — 3-кроковий онбординг для нових користувачів
│   │   ├── profile_page/            # ProfilePage — профіль + статистика системи
│   │   ├── sensors_page/            # SensorsPage — управління локаціями і сенсорами
│   │   └── telemetry/               # TelemetryPage (+ _ExportBottomSheet)
│   ├── services/
│   │   ├── cache_service.dart       # Офлайн-кеш останніх значень (SharedPreferences)
│   │   ├── export_service.dart      # Формування .xlsx і збереження в Downloads
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
    ├── 20260515115706_add_events_table.sql
    ├── 20260515125706_thresholds_rls.sql
    ├── 20260515130000_enable_telemetry_realtime.sql
    ├── 20260515160000_sensors_management_rls.sql
    └── 20260519120000_user_scoped_locations.sql   # user_id на locations + RLS per user
```

---

## 4. Потоки даних

### 4.1. Дашборд (HomePage)

```
HomePage.initState()
    → DashboardCubit(connectionBloc).startWatching()
         → emit DashboardLoading
         → _loadLocations()                          ← всі локації користувача
              вибрати активну (збережену або першу)
         → паралельно:
              _loadSensorsAndData()                  ← сенсори активної локації
                  SensorRepository.getSensorsByLocation(locationId)
                  _sensorTypes = сенсори.map(type).toSet()
                  для кожного сенсора паралельно:
                      TelemetryRepository.getLastTelemetry(limit: 1)
                      ThresholdRepository.getThreshold(sensorId)
              _loadLastAlert()                       ← остання подія
         → emit DashboardLoaded(temperature, humidity, pressure,
                                sensorTypes, lastAlert, locations,
                                activeLocationId, isFromCache: false)
         → CacheService.saveLastValues(locationId, {...})
         → Realtime підписки на сенсори активної локації
         → Realtime підписка на events

HomeContent (BlocBuilder)
    ├── state.locations.isEmpty
    │       → _EmptyState "Налаштуйте систему" → /onboarding
    ├── state.sensorTypes.isEmpty
    │       → _EmptyState "Немає сенсорів" → /sensors (+ reload після повернення)
    └── є сенсори
            ├── [офлайн-банер] (якщо isFromCache)
            ├── BackendStatusWidget
            ├── [lastAlert банер]
            ├── _SensorCards — тільки картки для існуючих типів сенсорів
            │       temperature + humidity → Row; кожен окремо → повна ширина
            │       pressure → повна ширина (якщо є)
            └── NavButtons (Телеметрія / Журнал подій / Сенсори)
                    "Сенсори" → reload() після повернення
    Pull-to-refresh → DashboardCubit.reload()

HomePage AppBar
    ├── title: _LocationSelector
    │       ├── 1 локація: Text з назвою
    │       └── 2+ локацій: DropdownButton → switchLocation(id)
    └── action: IconButton → /profile
```

- `DashboardCubit.reload()` — публічний метод; скасовує підписки, перезавантажує локації та сенсори, відновлює Realtime.
- `_loadLocations()` — збирає локації та визначає активну: якщо поточна ще існує — зберігає її; якщо ні або null — обирає першу.
- `switchLocation(id)` — скасовує підписки на сенсори, скидає дані, emits Loading, завантажує сенсори нової локації. Підписка на `events` зберігається.
- `DashboardSensorData.isExceeded` — `true` якщо `value > maxThreshold` або `value < minThreshold`.

**Офлайн-кеш:**
- При `ConnectionDisconnected` → re-emit з `isFromCache: true` або `_loadFromCache()`.
- При `ConnectionConnected` + `_isFromCache` → `_reload()` перезавантажує з мережі.

### 4.2. Онбординг (OnboardingPage)

```
AuthGuard → LocationRepository.getLocations()
    ├── locations.isEmpty → /onboarding
    └── locations.isNotEmpty → /home

OnboardingPage (PageView, 3 кроки)
    ├── крок 1: пояснення системи
    ├── крок 2: про локації
    └── крок 3: "Розпочати" → _CreateLocationSheet
                   LocationRepository.createLocation(name, address)
                   → Navigator.pushReplacementNamed('/home')
    "Пропустити" → /home (без створення локації)
```

### 4.3. Профіль (ProfilePage)

```
ProfilePage.initState()
    → ProfileCubit.load()
         → паралельно:
              LocationRepository.getLocations()
              SensorRepository.getAllSensors()
              EventRepository.getTodayEventsCount()
         → emit ProfileLoaded(locationCount, sensorCount, todayEventCount)
              ↓
    ProfilePage
         ├── Аватар (перша літера email, помаранчева рамка)
         ├── Email + "Учасник з {місяць рік}"
         ├── Статистика: локації / сенсори / події сьогодні
         └── Кнопка виходу → AuthCubit.signOut() → /login
```

### 4.4. Realtime телеметрія (TelemetryPage)

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

`TelemetryPage` отримує `locationId` і `locationName` як параметри навігації.

1. `initState()` → `SensorRepository.getSensorsByLocation(locationId)` — динамічний список сенсорів.
2. Вкладки `TabBar` — назва сенсора + одиниця: `"${sensor.name} (${sensor.unit})"` (наприклад "Кухня (°C)").
3. Для кожного сенсора — `TelemetryDataCubit(label: sensor.name, ...)` і `ThresholdCubit`.
4. `.NET` бекенд записує у `telemetry`; Realtime → `TelemetryDataCubit` → графік.

### 4.5. Перевірка порогів, сповіщення та запис події

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
    FCMService.showLocalNotification("⚠️ {sensor.name}", body)
    _lastNotification = now
    supabase.from('events').insert(...)  ← fire-and-forget (.ignore())
```

- Cooldown — 30 секунд на сенсор.
- Текст нотифікації: `"28.5°C перевищує максимум 26.0°C"`.

### 4.6. Журнал подій (EventsPage)

```
EventsPage.initState()
    → EventsCubit.loadAndWatch()
         → emit EventsLoading
         → EventRepository.getEvents(limit: 50)
         → emit EventsLoaded(events)
         → EventRepository.watchEvents() ← Realtime INSERT
              ↓ нова подія
         → emit EventsLoaded([newEvent, ...events])
```

- Час відображається відносно: "щойно / 5 хв тому / 2 год тому / дата".
- Pull-to-refresh → `EventsCubit.refresh()`.
- Червона картка: `threshold_type == 'max'`; синя: `threshold_type == 'min'`.

### 4.7. Управління локаціями і сенсорами (SensorsPage)

```
SensorsPage → SensorsCubit.load()
    ListView з _LocationTile (ExpansionTile)
         ├── Swipe вліво → AlertDialog → deleteLocation(id)
         ├── "+" всередині → _AddSensorSheet → addSensor(...)
         └── _SensorTile → Swipe вліво → deleteSensor(id)
    "+" у AppBar → _AddLocationSheet → addLocation(name, address)
```

- Cascade delete локацій через `ON DELETE CASCADE` у БД.

### 4.8. Автентифікація

```
LoginPage / RegisterPage
    → Navigator.pushNamedAndRemoveUntil('/', ...)  ← завжди через AuthGuard
         ↓
    AuthGuard._checkLocations()
         ├── locations.isEmpty → /onboarding
         └── locations.isNotEmpty → /home
```

- Google OAuth: `supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'com.example.test1://login-callback')`.
- Після авторизації браузер редиректить до Supabase → Supabase редиректить до `com.example.test1://login-callback` → intent-filter в `AndroidManifest.xml` перехоплює deep link → сесія встановлюється через `onAuthStateChange`.

### 4.9. Експорт телеметрії в Excel (TelemetryPage)

```
TelemetryPage AppBar → іконка "file_download"
    ↓ перевірка ConnectionBloc (офлайн → SnackBar)
    showModalBottomSheet → _ExportBottomSheet
        ├── "Від / До" → showDatePicker
        └── "Зберегти .xlsx"
                ↓
            ExportService.exportToXlsx(locationName, sensors, from, to)
                ├── Excel.createExcel() → sheet "Телеметрія"
                ├── header: [Час, Сенсор, Тип, Значення, Одиниця]
                ├── для кожного сенсора:
                │       ExportRepository.getTelemetryRange(sensorId, from, to)
                │       рядки: [datetime, sensor.name, тип, value, unit]
                ├── workbook.encode() → List<int>
                └── File('/storage/emulated/0/Download/chipidiezel_{name}_{date}.xlsx')
                ↓
            Navigator.pop + SnackBar "✓ Збережено в Завантаженнях: {filename}"
```

- Формат `.xlsx` нативно підтримує Unicode — проблема з кириличними символами відсутня.
- Якщо `/storage/emulated/0/Download` недоступний — fallback на `getDownloadsDirectory()` або temp.
- `WRITE_EXTERNAL_STORAGE` permission у `AndroidManifest.xml` з `android:maxSdkVersion="28"` (для Android < 10).

---

## 5. Управління станом

### DashboardCubit (`lib/presentation/cubits/`)

| Стан | Коли |
|---|---|
| `DashboardInitial` | До виклику `startWatching()` |
| `DashboardLoading` | Початкове завантаження, `switchLocation()`, `reload()` |
| `DashboardLoaded(temperature, humidity, pressure, sensorTypes, lastAlert, locations, activeLocationId, isFromCache)` | Дані є; оновлюється realtime |

Ключові методи:

| Метод | Опис |
|---|---|
| `startWatching()` | Завантажує локації → сенсори → підписки |
| `switchLocation(id)` | Скасовує підписки, скидає дані, завантажує нову локацію |
| `reload()` | Публічний; повне перезавантаження (локації + сенсори + підписки) |
| `_loadLocations()` | Завантажує локації; зберігає активну або обирає першу |
| `_emitLoaded()` | Єдина точка emit; автоматично зберігає в `CacheService` |

`DashboardSensorData` — value object:

| Поле | Тип | Опис |
|---|---|---|
| `value` | `double?` | Поточне значення |
| `lastUpdated` | `DateTime?` | Час запису (UTC → local) |
| `minThreshold` | `double?` | Мінімальний поріг |
| `maxThreshold` | `double?` | Максимальний поріг |
| `isExceeded` | `bool` | `true` якщо value за межами порогів |

`sensorTypes: List<String>` — перелік типів сенсорів активної локації; використовується в `HomeContent` для умовного рендерингу карток.

### ProfileCubit (`lib/src/cubit/profile/`)

| Стан | Коли |
|---|---|
| `ProfileInitial` | До виклику `load()` |
| `ProfileLoading` | Завантаження |
| `ProfileLoaded(locationCount, sensorCount, todayEventCount)` | Статистика готова |
| `ProfileError(message)` | Помилка |

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
| `TelemetryInitial` | До `loadAndWatch()` |
| `TelemetryLoading` | Початкове завантаження |
| `TelemetryLoaded(points)` | Дані є, оновлюються realtime |
| `TelemetryError(message)` | Помилка |

Конструктор приймає `label` (ім'я сенсора), `unit`, `sensorType`. `label` використовується в push-нотифікаціях.

### EventsCubit, SensorsCubit, ThresholdCubit, ConnectionBloc

Без змін відносно попередньої версії (детальний опис вище у розділі 4).

---

## 6. Репозиторії (`lib/data/repositories/`)

### LocationRepository

```dart
Future<List<Map<String, dynamic>>> getLocations()
// включає user_id фільтрацію через RLS (auth.uid())

Future<void> createLocation(String name, String address)
// вставляє user_id: supabase.auth.currentUser!.id

Future<void> deleteLocation(String id)
```

### EventRepository

```dart
Future<List<Map<String, dynamic>>> getEvents({int limit = 50})
Future<Stream<Map<String, dynamic>>> watchEvents()
Future<int> getTodayEventsCount()  // кількість подій з початку поточного UTC-дня
```

### SensorRepository

```dart
Future<List<Map<String, dynamic>>> getSensorsByLocation(String locationId)
Future<List<Map<String, dynamic>>> getAllSensors()
Future<void> createSensor(String locationId, String name, String type, String unit)
Future<void> deleteSensor(String id)
```

### TelemetryRepository, ThresholdRepository, ExportRepository

Без змін.

---

## 6а. Сервіси (`lib/src/services/`)

### ExportService

`exportToXlsx(locationName, sensors, from, to) → Future<String>`:
1. Для кожного сенсора викликає `ExportRepository.getTelemetryRange`.
2. Формує Excel workbook з листом "Телеметрія", колонки: Час, Сенсор, Тип, Значення, Одиниця.
3. Зберігає у `/storage/emulated/0/Download/chipidiezel_{name}_{YYYYMMDD}.xlsx`.
4. Повертає ім'я файлу для відображення в SnackBar.

### CacheService

Зберігає/зчитує JSON із `SharedPreferences`.

| Метод | Опис |
|---|---|
| `saveLastValues(locationId, values)` | Ключ `cache_location_{locationId}` |
| `getLastValues(locationId)` | Повертає `Map?` або `null` |
| `clear()` | Видаляє всі записи з префіксом `cache_location_` |

---

## 7. База даних (Supabase PostgreSQL)

### Схема

```sql
locations   (id uuid PK, name text, address text, user_id uuid FK→auth.users ON DELETE CASCADE,
             created_at timestamptz)
sensors     (id uuid PK, location_id uuid FK→locations ON DELETE CASCADE,
             name text, type text, unit text, created_at timestamptz)
telemetry   (id bigint IDENTITY PK, sensor_id uuid FK→sensors, value numeric, recorded_at timestamptz)
thresholds  (id uuid PK, sensor_id uuid FK→sensors UNIQUE, min_value numeric, max_value numeric)
events      (id bigint IDENTITY PK, sensor_id uuid FK→sensors ON DELETE CASCADE,
             sensor_type text, value numeric, threshold_type text,
             threshold_value numeric, triggered_at timestamptz DEFAULT now())
```

Індекси: `telemetry_sensor_time_idx ON telemetry(sensor_id, recorded_at DESC)`, `events_triggered_at_idx ON events(triggered_at DESC)`.

### RLS (мультитенантність)

Починаючи з міграції `20260519120000_user_scoped_locations.sql`, всі дані прив'язані до користувача через ланцюжок зовнішніх ключів:

```
auth.uid() → locations.user_id
           → sensors.location_id → locations.user_id
           → telemetry.sensor_id → sensors → locations.user_id
           → thresholds.sensor_id → sensors → locations.user_id
           → events.sensor_id → sensors → locations.user_id
```

| Таблиця | SELECT | INSERT | DELETE |
|---|---|---|---|
| locations | `user_id = auth.uid()` | `user_id = auth.uid()` | `user_id = auth.uid()` |
| sensors | через locations | через locations | через locations |
| telemetry | через sensors→locations | service_role (бекенд) | — |
| thresholds | через sensors→locations | через sensors→locations | через sensors→locations |
| events | через sensors→locations | через sensors→locations | — |

### Realtime

`telemetry` та `events` включені в `supabase_realtime` publication.

---

## 8. Графіки (`lib/src/widgets/telemetry_chart_widget.dart`)

`TelemetryChartWidget` — `fl_chart` лінійний графік:

- **X вісь:** порядковий індекс точки.
- **Y вісь:** значення + одиниця; діапазон включає порогові лінії.
- **Колір:** `°C` → червоний, `%` → синій, `hPa` → зелений.
- **Відображає:** останні 50 точок, максимум 100 у cubit.
- **Tooltip:** значення + одиниця при дотику.
- **Порогові лінії:** пунктирні через `ExtraLinesData` — червона (max), синя (min).

---

## 9. Push-повідомлення та локальні нотифікації

`FCMService.init()` — запитує дозвіл, створює Android channel `threshold_alerts`, налаштовує FCM. Firebase використовується **тільки для FCM**.

`FCMService.showLocalNotification(title, body)` — локальна нотифікація при спрацюванні порогу.

---

## 10. Маршрути

| Маршрут | Сторінка |
|---|---|
| `/` | `AuthGuard` → `/onboarding` або `/home` |
| `/login` | `LoginPage` |
| `/register` | `RegisterPage` |
| `/onboarding` | `OnboardingPage` (3-крокова, створення першої локації) |
| `/home` | `HomePage` (дашборд) |
| `/telemetry` | `TelemetryPage` (аргумент: `Map {locationId, locationName}`) |
| `/events` | `EventsPage` |
| `/sensors` | `SensorsPage` |
| `/profile` | `ProfilePage` |

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

```env
SUPABASE_URL=https://unjpmqtykfsywbvnrnry.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

### Supabase міграції

```bash
supabase link --project-ref unjpmqtykfsywbvnrnry
supabase db push
```

### Google OAuth (налаштування)

1. Google Cloud Console → OAuth 2.0 Client ID (Web) → Authorized redirect URIs:
   ```
   https://unjpmqtykfsywbvnrnry.supabase.co/auth/v1/callback
   ```
2. Supabase Dashboard → Authentication → Providers → Google → увімкнути, вставити Client ID і Secret.
3. Supabase Dashboard → Authentication → URL Configuration → Redirect URLs:
   ```
   com.example.test1://login-callback
   ```

### Firebase

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
flutter analyze       # Аналіз коду (перед кожним комітом)
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
