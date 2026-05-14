# Технічна документація: Smart Home "Чіпідізєль"

Цей документ описує внутрішню архітектуру, потоки даних та технічні особливості реалізації проекту.

## 1. Архітектурний паттерн

Проект побудований на поєднанні **Clean Architecture** та **BLoC/Cubit** для управління станом.

- **Presentation Layer:** Flutter віджети, що використовують `BlocBuilder` та `BlocListener` для реакції на зміни стану.
- **Domain Layer:** Опис сутностей (`Sensor`, `StationArgs`) та доменних моделей для екранів станції.
- **Data Layer:** Реалізація Supabase репозиторіїв, HTTP клієнт (`ApiClient`), MQTT клієнт та USB сервіс.
- **Business Logic Layer:** Cubit-и та BLoC для автентифікації, мережевого стану, сенсорів, станції та QR-сканера.

Окремі глобальні інтеграції винесені в `lib/core`:
- `supabase_client.dart` — глобальний доступ до `Supabase.instance.client`.
- `auth_guard.dart` — стартовий guard, який показує `LoginPage` або `HomePage` залежно від `AuthCubit`.

## 2. Потоки даних (Data Flow)

### 2.1. Моніторинг станції (MQTT)
1.  **Ініціалізація:** `MQTTClientWrapper` встановлює з'єднання з брокером через порт 8883 (SSL).
2.  **Підписка:** Після успішного підключення клієнт автоматично підписується на топіки:
    - `sensor/temperature`
    - `sensor/humidity`
    - `sensor/pressure`
3.  **Обробка:** При отриманні повідомлення, `MQTTClientWrapper` парсить корисне навантаження (payload) і через callback `onData` передає дані до `StationDataCubit`.
4.  **Оновлення UI:** `StationDataCubit` емітить новий стан `StationDataUpdated`, що призводить до перемальовування графіків або показників на екрані `SmartStationPage`.

### 2.2. Пряме керування (USB Serial)
1.  **Пошук пристроїв:** `UsbService` використовує плагін `usb_serial` для отримання списку підключених USB пристроїв.
2.  **З'єднання:** Встановлюється зв'язок з параметрами: `115200 baud`, `8 databits`, `1 stopbit`, `no parity`.
3.  **Передача:** Команди відправляються у вигляді `Uint8List` (байтовий потік) через метод `sendData`.

### 2.3. REST API (Управління сенсорами)
Додаток взаємодіє з локальним або віддаленим сервером (`192.168.1.133:5001`) для CRUD операцій над списком сенсорів:
- `GET /sensors` — отримання списку.
- `POST /sensors` — створення нового сенсора.
- `PUT /sensors/{id}` — оновлення.
- `DELETE /sensors/{id}` — видалення.

### 2.4. Supabase Database та Realtime
Для основного сховища телеметрії використовується Supabase PostgreSQL.

Репозиторії знаходяться в `lib/data/repositories`:
- `LocationRepository`
  - `getLocations()` — читає `locations`.
  - `createLocation(name, address)` — створює приміщення.
- `SensorRepository`
  - `getSensorsByLocation(locationId)` — читає сенсори за `location_id`.
  - `createSensor(locationId, name, type, unit)` — створює сенсор.
- `TelemetryRepository`
  - `getLastTelemetry(sensorId, limit: 50)` — читає останні записи з `telemetry`.
  - `watchTelemetry(sensorId)` — підписується на Supabase Realtime для `telemetry` з фільтром `sensor_id`.

Всі Supabase відповіді поки типізуються як `Map<String, dynamic>`. Репозиторії використовують `try/catch`, логують помилки через `dart:developer log(...)` і прокидають помилку вище для Cubit/BLoC рівня.

## 3. Управління станом (State Management)

### Ключові Cubit-и:
- **AuthCubit:** Працює з Supabase Auth, визначає початковий стан через `supabase.auth.currentUser`, слухає `supabase.auth.onAuthStateChange` і керує станами `AuthAuthenticated`, `AuthUnauthenticated`, `AuthLoading`, `AuthError`.
- **StationDataCubit:** Акумулює останні отримані дані від сенсорів (температура, вологість, тиск).
- **ConnectionBloc:** Глобальний блок, що моніторить стан мережі (Wi-Fi/Mobile Data) за допомогою `connectivity_plus`.
- **SensorListCubit:** Керує завантаженням та відображенням списку сенсорів з API.

## 4. Безпека та Автентифікація

- **Supabase Auth:** Використовується для email/password входу, реєстрації, виходу та Google OAuth.
- **Email/password:** `AuthCubit.signIn()` викликає `supabase.auth.signInWithPassword()`, `AuthCubit.signUp()` викликає `supabase.auth.signUp()`.
- **Google OAuth:** `AuthCubit.signInWithGoogle()` викликає `supabase.auth.signInWithOAuth(OAuthProvider.google)`.
- **Сесія:** Supabase SDK зберігає сесію автоматично. Додаток не використовує `SharedPreferences` для auth токенів.
- **Обробка помилок:** `AuthException` перетворюється на зрозумілі повідомлення українською у `AuthCubit`.
- **Lifecycle:** підписка `onAuthStateChange` закривається в `AuthCubit.close()`.
- **Firebase Auth:** видалено з auth логіки. Firebase залишається тільки для FCM.
- **MQTT SSL:** `MQTTClientWrapper` використовує `SecurityContext.defaultContext` для захищеного з'єднання.

## 5. Робота з Push-повідомленнями

`FCMService` ініціалізується при запуску додатку:
- Налаштовує обробку повідомлень у фоновому та активному режимах.
- Використовує `FirebaseMessaging` для отримання токена пристрою, який може бути використаний сервером для таргетованих сповіщень про аварійні стани станції.

## 6. Вимоги до оточення

- **Min SDK:** Android 21+, iOS 12.0+
- **Supabase:** у корені проєкту має бути `.env` з `SUPABASE_URL` та `SUPABASE_ANON_KEY`; файл не комітиться.
- **Серверна частина:** очікується наявність REST API на порті 5001 та MQTT брокера для legacy/станційних сценаріїв.
- **Firebase:** конфігурація потрібна для Firebase Cloud Messaging.
