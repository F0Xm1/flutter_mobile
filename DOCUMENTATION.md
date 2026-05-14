# Документація проекту: Smart Home "Чіпідізєль" (Mobile Lab)

Цей проект є мобільним додатком на базі Flutter для управління системою розумного дому або промисловою станцією ("Чіпідізєль"). Додаток підтримує роботу з сенсорами, керування станціями через MQTT та USB, Supabase Database/Realtime, а також автентифікацію через Supabase Auth.

## 🚀 Технологічний стек

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [BLoC / Cubit](https://pub.dev/packages/flutter_bloc)
- **Database/Auth/Realtime:** [Supabase](https://supabase.com/) (PostgreSQL, Auth, Realtime)
- **Push:** [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- **Протоколи зв'язку:** 
  - **MQTT:** для віддаленого керування станціями.
  - **USB Serial:** для прямого підключення до обладнання.
- **Dependency Injection:** Provider
- **Env:** `flutter_dotenv` для локальних ключів Supabase

## 📂 Структура проекту

Проект організований за принципами Clean Architecture (з певними спрощеннями):

```text
lib/
├── core/
│   ├── auth_guard.dart     # Guard для вибору LoginPage/HomePage за auth станом
│   └── supabase_client.dart # Глобальний Supabase client
├── data/
│   └── repositories/       # Supabase репозиторії: locations, sensors, telemetry
├── src/
│   ├── bloc/               # Глобальні BLoC для управління станом (напр. Connection)
│   ├── cubit/              # Cubit-и для окремих модулів (Auth, Scanner, Sensors, Station)
│   ├── data/               # Legacy API клієнти / локальні data-компоненти
│   ├── domain/             # Моделі даних для існуючих екранів
│   ├── extensions/         # Розширення для базових типів (Double тощо)
│   ├── screens/            # UI екрани (Auth, Home, Scanner, Sensor)
│   ├── services/           # Зовнішні сервіси (MQTT, FCM, USB)
│   └── widgets/            # Перевикористовувані UI компоненти
├── firebase_options.dart   # Конфігурація Firebase
└── main.dart               # Точка входу в додаток
supabase/
└── migrations/             # SQL міграції Supabase
```

## 🛠 Ключові модулі

### 1. Автентифікація (`lib/src/cubit/auth`)
Підтримує вхід через Email/Password, реєстрацію, вихід та Google OAuth через Supabase Auth.

`AuthCubit`:
- визначає стартовий стан через `supabase.auth.currentUser`;
- слухає `supabase.auth.onAuthStateChange`;
- емітить `AuthAuthenticated`, `AuthUnauthenticated`, `AuthLoading`, `AuthError`;
- закриває auth-підписку в `close()`.

`AuthGuard` у `lib/core/auth_guard.dart` використовується на стартовому маршруті `/` і показує `LoginPage` або `HomePage` залежно від поточного auth стану.

### 2. Керування станцією (`lib/src/cubit/station`)
- **SmartStationPage:** Основний екран моніторингу станції.
- **MQTT Service:** Забезпечує отримання даних в реальному часі та відправку команд.

### 3. Робота з сенсорами (`lib/src/cubit/sensor`)
Дозволяє переглядати список сенсорів, редагувати їх параметри та моніторити показники.

Supabase data-layer репозиторії:
- `LocationRepository` — читання/створення записів `locations`.
- `SensorRepository` — читання/створення записів `sensors`.
- `TelemetryRepository` — читання останньої телеметрії та Realtime-підписка на `telemetry`.

### 4. Сканер QR-кодів (`lib/src/cubit/scanner`)
Використовується для швидкого додавання нових станцій або ідентифікації обладнання за допомогою камери.

### 5. USB Зв'язок (`lib/src/services/usb`)
Реалізовано сервіс для взаємодії з пристроями через USB Serial порт (актуально для Android пристроїв).

### 6. Push-повідомлення (`lib/src/services/push_mess`)
Інтеграція з Firebase Cloud Messaging (FCM) для отримання критичних сповіщень від системи. Firebase Auth у проєкті більше не використовується.

## ⚙️ Налаштування та запуск

1.  **Вимоги:** Flutter SDK (^3.2.6) та встановлений Android Studio / Xcode.
2.  **Залежності:** Виконайте `flutter pub get`.
3.  **Supabase env:**
    - Створіть `.env` у корені проєкту.
    - Додайте `SUPABASE_URL` та `SUPABASE_ANON_KEY`.
    - `.env` не комітиться.
4.  **Firebase FCM:** 
    - Проект вже містить `google-services.json` для Android та `GoogleService-Info.plist` для iOS.
    - Переконайтеся, що ви маєте доступ до відповідного Firebase проекту для push-повідомлень.
5.  **Запуск:** `flutter run`.

## 📈 Візуалізація даних
Для побудови графіків використовується бібліотека `fl_chart`, що дозволяє відображати історію показників сенсорів у зручному вигляді.

---
Документація створена для розробників та технічних спеціалістів, що працюють над проектом.
