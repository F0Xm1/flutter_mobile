# Технічна документація: Smart Telemetry System "Чіпідізєль"

Цей документ описує внутрішню архітектуру, потоки даних та технічні особливості реалізації проекту.

## 1. Архітектурний паттерн

Проект побудований на поєднанні **Clean Architecture** та **BLoC/Cubit** для управління станом.

- **Presentation Layer:** Flutter віджети, що використовують `BlocBuilder` та `BlocListener` для реакції на зміни стану.
- **Domain Layer:** відсутній окремий шар — моделі не потрібні, репозиторії повертають `Map<String, dynamic>`.
- **Data Layer:** Supabase репозиторії (`LocationRepository`, `SensorRepository`, `TelemetryRepository`).
- **Business Logic Layer:** `AuthCubit` (auth), `TelemetryDataCubit` (realtime дані), `ConnectionBloc` (мережа).

Глобальні інтеграції в `lib/core`:
- `supabase_client.dart` — глобальний геттер `Supabase.instance.client`.
- `auth_guard.dart` — стартовий guard, який перенаправляє на `LoginPage` або `HomePage` залежно від `AuthCubit`.

## 2. Потоки даних (Data Flow)

### 2.1. Realtime телеметрія (Supabase)

```
.NET Simulator → MQTT → .NET Listener → Supabase PostgreSQL
                                               ↓
                              Supabase Realtime WebSocket
                                               ↓
                                    TelemetryRepository.watchTelemetry()
                                               ↓
                                    TelemetryDataCubit (stream subscription)
                                               ↓
                                    TelemetryPage → TelemetryChartWidget
```

1. `.NET` бекенд отримує MQTT-повідомлення від симулятора і записує їх у таблицю `telemetry` в Supabase.
2. `TelemetryRepository.watchTelemetry(sensorId)` відкриває `RealtimeChannel` і підписується на `postgres_changes` event для таблиці `telemetry` з фільтром `sensor_id`.
3. `TelemetryDataCubit.loadAndWatch(sensorId)` спочатку завантажує останні 50 записів через `getLastTelemetry()`, потім підписується на stream. Нові точки додаються в список, зберігаючи максимум 100.
4. `TelemetryPage` відображає три вкладки (температура / вологість / тиск), кожна зі своїм екземпляром `TelemetryDataCubit`, ініціалізованим у `initState()` — підписка живе на весь час відкритої сторінки і не перестворюється при перемиканні вкладок.

### 2.2. Завантаження початкового стану

При відкритті `TelemetryPage`:
1. `TelemetryDataCubit` емітить `TelemetryLoading`.
2. Викликається `TelemetryRepository.getLastTelemetry(sensorId, limit: 50)`.
3. Supabase повертає записи впорядковані `recorded_at desc`, список реверсується (старіші — перші).
4. Емітується `TelemetryLoaded(points)`.

### 2.3. Автентифікація

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
- При `signOut()` Supabase SDK очищає сесію автоматично.
- Google OAuth: `supabase.auth.signInWithOAuth(OAuthProvider.google)` відкриває браузер.
- Email-підтвердження вимкнено (`enable_confirmations = false` в Supabase config).

## 3. Управління станом (State Management)

### AuthCubit (`lib/src/cubit/auth/`)

| Стан | Коли |
|---|---|
| `AuthInitial` | До першої перевірки сесії |
| `AuthLoading` | Під час запиту sign-in / sign-up / sign-out |
| `AuthAuthenticated` | Суpabase сесія активна |
| `AuthUnauthenticated` | Немає сесії або після виходу |
| `AuthError(message)` | Помилка Supabase Auth |

### TelemetryDataCubit (`lib/src/cubit/telemetry/`)

| Стан | Коли |
|---|---|
| `TelemetryInitial` | `SENSOR_ID_*` не задано у `.env` |
| `TelemetryLoading` | Початкове завантаження з Supabase |
| `TelemetryLoaded(points)` | Дані завантажені, список поновлюється realtime |
| `TelemetryError(message)` | Помилка мережі або Supabase |

### ConnectionBloc (`lib/src/bloc/connection/`)

Глобальний блок, що моніторить стан мережі через `connectivity_plus`. Відображається на `HomePage` — блокує кнопку "Телеметрія" при відсутності інтернету.

## 4. База даних (Supabase PostgreSQL)

### Схема

```sql
locations   (id uuid PK, name text, address text, created_at timestamptz)
sensors     (id uuid PK, location_id uuid FK→locations, name text, type text, unit text, created_at timestamptz)
telemetry   (id bigint IDENTITY PK, sensor_id uuid FK→sensors, value numeric, recorded_at timestamptz)
thresholds  (id uuid PK, sensor_id uuid FK→sensors, min_value numeric, max_value numeric)
```

Індекс: `telemetry_sensor_time_idx ON telemetry(sensor_id, recorded_at DESC)` — прискорює запити останніх записів.

### RLS політики

RLS увімкнено на всіх таблицях. Роль `authenticated` (будь-який залогінений користувач) має `SELECT` на всі таблиці.

| Таблиця | authenticated SELECT |
|---|---|
| locations | ✅ |
| sensors | ✅ |
| telemetry | ✅ |
| thresholds | ✅ |

### Сенсори (поточні UUID)

| Тип | UUID | Одиниця |
|---|---|---|
| temperature | `08769695-abd6-48de-a5b6-f2b9f3e2dc74` | °C |
| humidity | `8f9c6a83-f16b-4ffa-ae5b-5495271f16df` | % |
| pressure | `237d9612-a86d-437e-a118-d0bf5bfc6833` | hPa |

UUID задаються у `.env` через `SENSOR_ID_TEMPERATURE`, `SENSOR_ID_HUMIDITY`, `SENSOR_ID_PRESSURE`.

## 5. Репозиторії (`lib/data/repositories/`)

### TelemetryRepository

```dart
// Останні N записів (за замовчуванням 50), впорядковані desc
Future<List<Map<String, dynamic>>> getLastTelemetry(String sensorId, {int limit = 50})

// Realtime stream нових записів через Supabase RealtimeChannel
Stream<Map<String, dynamic>> watchTelemetry(String sensorId)
```

`watchTelemetry` повертає `StreamController`-based stream. При підписці відкриває `RealtimeChannel`, при скасуванні — видаляє його через `supabase.removeChannel()`.

### LocationRepository / SensorRepository

Використовуються для читання даних про приміщення та сенсори. У поточній версії мобільний додаток виконує тільки `SELECT` операції.

## 6. Візуалізація (`lib/src/widgets/telemetry_chart_widget.dart`)

`TelemetryChartWidget` використовує `fl_chart ^0.70` для побудови лінійного графіка:

- **X вісь:** порядковий індекс точки (0..N).
- **Y вісь:** числове значення телеметрії + одиниця виміру.
- **Колір лінії:** `°C` → червоний, `%` → синій, `hPa` → зелений.
- **Відображає:** останні 50 точок із наданого списку.
- **Анімація:** `duration: 300ms` при оновленні точок.
- **Tooltip:** показує `value + unit` при дотику до лінії.

## 7. Push-повідомлення

`FCMService` (`lib/src/services/push_mess/fcm_service.dart`) ініціалізується при запуску через `FCMService.init()`:
- Запитує дозвіл на нотифікації.
- Налаштовує обробники для foreground і background повідомлень.
- Firebase використовується **тільки для FCM** — Firebase Auth у проекті не застосовується.
- FCM токен логується для відлагодження; надсилання на бекенд не реалізовано в мобільному клієнті.

## 8. Конфігурація оточення

### `.env` (не комітити)

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SENSOR_ID_TEMPERATURE=<uuid>
SENSOR_ID_HUMIDITY=<uuid>
SENSOR_ID_PRESSURE=<uuid>
```

`main.dart` завантажує `.env` через `flutter_dotenv`. Якщо ключі відсутні — `StateError` на старті.

### Supabase CLI

Проект прив'язаний до remote Supabase проекту (`supabase link`). Міграції застосовуються через `supabase db push`. Auth конфіг — через `supabase config push`.

## 9. Маршрутизація

| Маршрут | Сторінка |
|---|---|
| `/` | `AuthGuard` |
| `/login` | `LoginPage` |
| `/register` | `RegisterPage` |
| `/home` | `HomePage` |
| `/telemetry` | `TelemetryPage` |

## 10. Вимоги до оточення

- **Flutter SDK:** ^3.2.6
- **Dart SDK:** ^3.2.6
- **Android:** min SDK 21+
- **iOS:** 12.0+
- **Supabase:** активний проект, застосовані міграції
- **Firebase:** `google-services.json` (Android) та `GoogleService-Info.plist` (iOS) для FCM
