# Технічна документація: Smart Telemetry System "Чіпідізєль"

Цей документ описує внутрішню архітектуру, потоки даних та технічні особливості реалізації проекту.

## 1. Архітектурний паттерн

Проект побудований на поєднанні **Clean Architecture** та **BLoC/Cubit** для управління станом.

- **Presentation Layer:** Flutter віджети, що використовують `BlocBuilder` та `BlocListener` для реакції на зміни стану.
- **Domain Layer:** відсутній окремий шар — моделі не потрібні, репозиторії повертають `Map<String, dynamic>`.
- **Data Layer:** Supabase репозиторії (`LocationRepository`, `SensorRepository`, `TelemetryRepository`, `ThresholdRepository`).
- **Business Logic Layer:** `AuthCubit` (auth), `TelemetryDataCubit` (realtime дані + перевірка порогів), `ThresholdCubit` (налаштування порогів), `ConnectionBloc` (мережа).

Глобальні інтеграції в `lib/core`:
- `supabase_client.dart` — глобальний геттер `Supabase.instance.client`.
- `auth_guard.dart` — стартовий guard, який перенаправляє на `LoginPage` або `HomePage` залежно від `AuthCubit`.

## 2. Потоки даних (Data Flow)

### 2.1. Realtime телеметрія (Supabase)

```
.NET Simulator → MQTT → .NET Listener → Supabase PostgreSQL
                                               ↓
                              Supabase Realtime WebSocket (postgres_changes)
                                               ↓
                                    TelemetryRepository.watchTelemetry()
                                               ↓
                                    TelemetryDataCubit (stream subscription)
                                          ↓           ↓
                              TelemetryPage     _checkThreshold()
                            TelemetryChartWidget      ↓
                                               FCMService.showLocalNotification()
```

1. `.NET` бекенд отримує MQTT-повідомлення від симулятора і записує їх у таблицю `telemetry` в Supabase.
2. `TelemetryRepository.watchTelemetry(sensorId)` відкриває `RealtimeChannel` і підписується на `postgres_changes` event для таблиці `telemetry` з фільтром `sensor_id`. Таблиця включена в PostgreSQL publication `supabase_realtime`.
3. `TelemetryDataCubit.loadAndWatch(sensorId)` спочатку завантажує останні 50 записів через `getLastTelemetry()`, потім підписується на stream. Нові точки додаються в список, зберігаючи максимум 100.
4. При кожному новому значенні викликається `_checkThreshold()` — якщо значення виходить за межі і cooldown (30 с) минув, надсилається локальна нотифікація.
5. `TelemetryPage` відображає три вкладки (температура / вологість / тиск), кожна зі своїм екземпляром `TelemetryDataCubit` та `ThresholdCubit`, ініціалізованих у `initState()`.

### 2.2. Завантаження початкового стану та порогів

При відкритті `TelemetryPage`:
1. `TelemetryDataCubit` емітить `TelemetryLoading`.
2. Викликається `TelemetryRepository.getLastTelemetry(sensorId, limit: 50)`.
3. Supabase повертає записи впорядковані `recorded_at desc`, список реверсується (старіші — перші).
4. Емітується `TelemetryLoaded(points)`.
5. Паралельно `ThresholdCubit.load(sensorId)` завантажує пороги. Після завершення викликається `TelemetryDataCubit.updateThreshold(min, max)`.

### 2.3. Перевірка порогів та сповіщення

```
Realtime point arrives → TelemetryDataCubit listener
                              ↓
                      emit TelemetryLoaded (updated points)
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
```

- Cooldown — 30 секунд з моменту останньої нотифікації на сенсор.
- Якщо пороги не встановлені (null) — перевірка не виконується.
- Текст нотифікації: `"28.5°C перевищує максимум 26.0°C"` або `"18.2°C нижче мінімуму 20.0°C"`.

### 2.4. Автентифікація

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
| `AuthAuthenticated` | Supabase сесія активна |
| `AuthUnauthenticated` | Немає сесії або після виходу |
| `AuthError(message)` | Помилка Supabase Auth |

### TelemetryDataCubit (`lib/src/cubit/telemetry/`)

| Стан | Коли |
|---|---|
| `TelemetryInitial` | `SENSOR_ID_*` не задано у `.env` |
| `TelemetryLoading` | Початкове завантаження з Supabase |
| `TelemetryLoaded(points)` | Дані завантажені, список поновлюється realtime |
| `TelemetryError(message)` | Помилка мережі або Supabase |

Внутрішній стан (не в emit):
- `_minThreshold`, `_maxThreshold` — поточні пороги, оновлюються через `updateThreshold()`.
- `_lastNotification` — час останньої нотифікації для cooldown.

### ThresholdCubit (`lib/src/cubit/threshold/`)

| Стан | Коли |
|---|---|
| `ThresholdInitial` | До виклику `load()` |
| `ThresholdLoading` | Під час завантаження або збереження |
| `ThresholdLoaded(min, max)` | Пороги завантажені (min/max можуть бути null) |
| `ThresholdError(message)` | Помилка Supabase |

### ConnectionBloc (`lib/src/bloc/connection/`)

Глобальний блок, що моніторить стан мережі через `connectivity_plus`. Відображається на `HomePage` — блокує кнопку "Телеметрія" при відсутності інтернету.

## 4. База даних (Supabase PostgreSQL)

### Схема

```sql
locations   (id uuid PK, name text, address text, created_at timestamptz)
sensors     (id uuid PK, location_id uuid FK→locations, name text, type text, unit text, created_at timestamptz)
telemetry   (id bigint IDENTITY PK, sensor_id uuid FK→sensors, value numeric, recorded_at timestamptz)
thresholds  (id uuid PK, sensor_id uuid FK→sensors UNIQUE, min_value numeric, max_value numeric)
```

Індекс: `telemetry_sensor_time_idx ON telemetry(sensor_id, recorded_at DESC)` — прискорює запити останніх записів.

`thresholds.sensor_id` має унікальний constraint (`thresholds_sensor_id_key`) — один запис на сенсор. Upsert використовує `onConflict: 'sensor_id'`.

### RLS політики

RLS увімкнено на всіх таблицях.

| Таблиця | SELECT | INSERT | UPDATE |
|---|---|---|---|
| locations | authenticated | — | — |
| sensors | authenticated | — | — |
| telemetry | authenticated | — | — |
| thresholds | authenticated | authenticated | authenticated |

### Realtime publication

Таблиця `telemetry` включена в PostgreSQL publication `supabase_realtime`:
```sql
alter publication supabase_realtime add table telemetry;
```
Без цього `postgres_changes` WebSocket events не надходять до клієнта, хоча REST-запити працюють нормально.

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
// Логує статус підписки (subscribed / channelError / timedOut)
Stream<Map<String, dynamic>> watchTelemetry(String sensorId)
```

`watchTelemetry` повертає `StreamController`-based stream. При підписці відкриває `RealtimeChannel` і логує `RealtimeSubscribeStatus`. При скасуванні — видаляє канал через `supabase.removeChannel()`.

### ThresholdRepository

```dart
// Повертає null якщо пороги ще не встановлені для цього сенсора
Future<Map<String, dynamic>?> getThreshold(String sensorId)

// Upsert по sensor_id (onConflict: 'sensor_id')
Future<void> upsertThreshold(String sensorId, double? min, double? max)
```

### LocationRepository / SensorRepository

Використовуються для читання даних про приміщення та сенсори. У поточній версії мобільний додаток виконує тільки `SELECT` операції.

## 6. Візуалізація (`lib/src/widgets/telemetry_chart_widget.dart`)

`TelemetryChartWidget` використовує `fl_chart` (git main) для побудови лінійного графіка:

- **X вісь:** порядковий індекс точки (0..N).
- **Y вісь:** числове значення телеметрії + одиниця виміру. Діапазон автоматично розширюється, якщо пороги виходять за межі даних.
- **Колір лінії:** `°C` → червоний, `%` → синій, `hPa` → зелений.
- **Відображає:** останні 50 точок із наданого списку.
- **Анімація:** `duration: 300ms` при оновленні точок.
- **Tooltip:** показує `value + unit` при дотику до лінії.
- **Порогові лінії:** горизонтальні пунктирні лінії через `ExtraLinesData` — червона (max), синя (min), з підписами `"max: 26.0 °C"` / `"min: 18.0 °C"`.

## 7. Push-повідомлення та локальні нотифікації

`FCMService` (`lib/src/services/push_mess/fcm_service.dart`) ініціалізується при запуску через `FCMService.init()`:
- Запитує дозвіл на нотифікації.
- Явно створює Android notification channel `threshold_alerts` (Importance.high) через `createNotificationChannel`.
- Налаштовує обробники для foreground і background FCM-повідомлень.
- Firebase використовується **тільки для FCM** — Firebase Auth у проекті не застосовується.
- FCM токен логується для відлагодження.

`FCMService.showLocalNotification(title, body)` — показує локальну нотифікацію через `flutter_local_notifications` (не FCM push). Використовує channel `threshold_alerts`.

## 8. Конфігурація оточення

### `.env` (не комітити)

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SENSOR_ID_TEMPERATURE=<uuid>
SENSOR_ID_HUMIDITY=<uuid>
SENSOR_ID_PRESSURE=<uuid>
```

`main.dart` завантажує `.env` через `flutter_dotenv` (опціонально). Якщо ключі відсутні і в `.env`, і в `--dart-define` — `StateError` на старті.

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
- **Supabase:** активний проект, застосовані міграції, таблиця `telemetry` в publication `supabase_realtime`
- **Firebase:** `google-services.json` (Android) та `GoogleService-Info.plist` (iOS) для FCM
