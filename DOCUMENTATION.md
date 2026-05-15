# Документація проекту: Smart Telemetry System "Чіпідізєль"

Мобільний додаток на Flutter для моніторингу телеметрії (температура, вологість, тиск) із сенсорів у комерційних приміщеннях у реальному часі.

## Технологічний стек

| Компонент | Технологія |
|---|---|
| Mobile | Flutter / Dart |
| State management | BLoC / Cubit (`flutter_bloc`) |
| Database | Supabase (PostgreSQL) |
| Realtime | Supabase Realtime (WebSocket) |
| Auth | Supabase Auth (email/password + Google OAuth) |
| Push | Firebase Cloud Messaging |
| Charts | fl_chart |
| Мережа | connectivity_plus |
| Backend | .NET Minimal API + MQTTnet (окремий репозиторій) |
| Env | flutter_dotenv |
| DI | provider (MultiProvider) |

## Структура проекту

```text
lib/
├── core/
│   ├── auth_guard.dart          # Redirect LoginPage/HomePage за auth станом
│   └── supabase_client.dart     # Глобальний геттер supabase client
├── data/
│   └── repositories/
│       ├── location_repository.dart
│       ├── sensor_repository.dart
│       └── telemetry_repository.dart
├── src/
│   ├── bloc/connection/         # ConnectionBloc — моніторинг мережі
│   ├── cubit/
│   │   ├── auth/                # AuthCubit + AuthState
│   │   └── telemetry/           # TelemetryDataCubit + TelemetryDataState
│   ├── screens/
│   │   ├── auth_page/           # LoginPage, RegisterPage
│   │   ├── home_page/           # HomePage, HomeContent
│   │   └── telemetry/           # TelemetryPage
│   ├── services/
│   │   └── push_mess/           # FCMService
│   └── widgets/
│       ├── telemetry_chart_widget.dart
│       └── reusable/            # ReusableTextField
├── firebase_options.dart
└── main.dart
supabase/
├── config.toml
└── migrations/
    ├── 20260514115031_init_tables.sql
    └── 20260514184751_add_rls_policies.sql
```

## Ключові модулі

### Автентифікація

`AuthCubit` (`lib/src/cubit/auth/`) керує всім циклом auth:
- Слухає `supabase.auth.onAuthStateChange` — стан синхронізується автоматично.
- `signIn(email, password)` → `supabase.auth.signInWithPassword()`.
- `signUp(email, password)` → `supabase.auth.signUp()` (email-підтвердження вимкнено).
- `signInWithGoogle()` → `supabase.auth.signInWithOAuth(OAuthProvider.google)`.
- `signOut()` → `supabase.auth.signOut()`.

`AuthGuard` на маршруті `/` перенаправляє залогінених на `HomePage`, незалогінених — на `LoginPage`.

### Realtime телеметрія

`TelemetryPage` (`lib/src/screens/telemetry/`) — головний екран моніторингу:
- Три вкладки: **Температура**, **Вологість**, **Тиск**.
- Кожна вкладка показує поточне значення великим шрифтом + лінійний графік з 50 останніх точок.
- Три окремі `TelemetryDataCubit` ініціалізуються в `initState()` — підписки живуть на весь час відкритої сторінки.

`TelemetryDataCubit` (`lib/src/cubit/telemetry/`):
- `loadAndWatch(sensorId)` — завантажує останні 50 точок, потім підписується на Supabase Realtime.
- Зберігає максимум 100 точок (старіші витісняються).
- Підписка автоматично закривається в `close()`.

### Графіки

`TelemetryChartWidget` (`lib/src/widgets/`):
- Лінійний графік (`fl_chart`).
- Кольори: температура — червоний, вологість — синій, тиск — зелений.
- Анімація 300ms при додаванні нової точки.
- Tooltip із значенням при дотику.

### Push-повідомлення

`FCMService.init()` викликається при старті. Запитує дозвіл, налаштовує обробники foreground/background повідомлень. Firebase використовується **тільки для FCM** — не для Auth.

### Моніторинг мережі

`ConnectionBloc` (глобальний) відстежує стан мережі. `HomePage` показує іконку WiFi та статус; кнопка "Телеметрія" неактивна при відсутності інтернету.

### Вихід з акаунту

`HomePage` має AppBar з кнопкою виходу → `AuthCubit.signOut()` → redirect на `/login`.

## Налаштування та запуск

### 1. Передумови

- Flutter SDK ^3.2.6
- Supabase CLI (`brew install supabase/tap/supabase`)

### 2. Клонування та залежності

```bash
git clone <repo>
cd mobile_lab
flutter pub get
```

### 3. Конфігурація `.env`

Створіть `.env` у корені проекту:

```env
SUPABASE_URL=https://unjpmqtykfsywbvnrnry.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SENSOR_ID_TEMPERATURE=08769695-abd6-48de-a5b6-f2b9f3e2dc74
SENSOR_ID_HUMIDITY=8f9c6a83-f16b-4ffa-ae5b-5495271f16df
SENSOR_ID_PRESSURE=237d9612-a86d-437e-a118-d0bf5bfc6833
```

`.env` не комітити (є в `.gitignore`).

### 4. Supabase міграції

```bash
supabase link --project-ref unjpmqtykfsywbvnrnry
supabase db push
```

### 5. Firebase

Файли конфігурації вже включені в репозиторій:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

### 6. Запуск

```bash
flutter run
```

## База даних

### Таблиці

```sql
locations   (id uuid PK, name text, address text, created_at timestamptz)
sensors     (id uuid PK, location_id uuid FK, name text, type text, unit text, created_at timestamptz)
telemetry   (id bigint PK, sensor_id uuid FK, value numeric, recorded_at timestamptz)
thresholds  (id uuid PK, sensor_id uuid FK, min_value numeric, max_value numeric)
```

### RLS

Усі таблиці захищені Row Level Security. Роль `authenticated` має `SELECT` на всі таблиці. Запис у `telemetry` виконує тільки .NET бекенд через `service_role` ключ.

## Маршрути

| Маршрут | Сторінка |
|---|---|
| `/` | `AuthGuard` |
| `/login` | `LoginPage` |
| `/register` | `RegisterPage` |
| `/home` | `HomePage` |
| `/telemetry` | `TelemetryPage` |

## Команди розробника

```bash
flutter run          # Запуск
flutter analyze      # Аналіз коду
flutter pub get      # Залежності
supabase db push     # Застосувати міграції
supabase config push # Синхронізувати auth конфіг
```

## Що НЕ робити

- Не комітити `.env`
- Не використовувати `service_role` ключ у Flutter — він для .NET бекенду
- Не хардкодити IP-адреси, URL або ключі
- Не використовувати Firebase Auth — тільки Supabase Auth
- Не класти бізнес-логіку у віджети — тільки у Cubit-и
- Не використовувати `print()` — тільки `log()` з `dart:developer`
