# Документація проекту: Smart Home "Чіпідізєль" (Mobile Lab)

Цей проект є мобільним додатком на базі Flutter для управління системою розумного дому або промисловою станцією ("Чіпідізєль"). Додаток підтримує роботу з сенсорами, керування станціями через MQTT та USB, а також автентифікацію через Firebase.

## 🚀 Технологічний стек

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [BLoC / Cubit](https://pub.dev/packages/flutter_bloc)
- **Backend/Auth:** [Firebase](https://firebase.google.com/) (Auth, Cloud Messaging)
- **Протоколи зв'язку:** 
  - **MQTT:** для віддаленого керування станціями.
  - **USB Serial:** для прямого підключення до обладнання.
- **Dependency Injection:** Provider
- **Локальне сховище:** Shared Preferences

## 📂 Структура проекту

Проект організований за принципами Clean Architecture (з певними спрощеннями):

```text
lib/
├── src/
│   ├── bloc/               # Глобальні BLoC для управління станом (напр. Connection)
│   ├── business/           # Use Cases (логіка автентифікації, реєстрації)
│   ├── cubit/              # Cubit-и для окремих модулів (Auth, Scanner, Sensors, Station)
│   ├── data/               # Реалізація репозиторіїв та API клієнтів
│   ├── domain/             # Моделі даних та інтерфейси репозиторіїв
│   ├── extensions/         # Розширення для базових типів (Double тощо)
│   ├── screens/            # UI екрани (Auth, Home, Scanner, Sensor)
│   ├── services/           # Зовнішні сервіси (MQTT, FCM, USB)
│   └── widgets/            # Перевикористовувані UI компоненти
├── firebase_options.dart   # Конфігурація Firebase
└── main.dart               # Точка входу в додаток
```

## 🛠 Ключові модулі

### 1. Автентифікація (`lib/src/cubit/auth`)
Підтримує вхід через Email/Password та Google Sign-In. Логіка винесена в Use Cases (`business/use_cases`).

### 2. Керування станцією (`lib/src/cubit/station`)
- **SmartStationPage:** Основний екран моніторингу станції.
- **MQTT Service:** Забезпечує отримання даних в реальному часі та відправку команд.

### 3. Робота з сенсорами (`lib/src/cubit/sensor`)
Дозволяє переглядати список сенсорів, редагувати їх параметри та моніторити показники.

### 4. Сканер QR-кодів (`lib/src/cubit/scanner`)
Використовується для швидкого додавання нових станцій або ідентифікації обладнання за допомогою камери.

### 5. USB Зв'язок (`lib/src/services/usb`)
Реалізовано сервіс для взаємодії з пристроями через USB Serial порт (актуально для Android пристроїв).

### 6. Push-повідомлення (`lib/src/services/push_mess`)
Інтеграція з Firebase Cloud Messaging (FCM) для отримання критичних сповіщень від системи.

## ⚙️ Налаштування та запуск

1.  **Вимоги:** Flutter SDK (^3.2.6) та встановлений Android Studio / Xcode.
2.  **Залежності:** Виконайте `flutter pub get`.
3.  **Firebase:** 
    - Проект вже містить `google-services.json` для Android та `GoogleService-Info.plist` для iOS.
    - Переконайтеся, що ви маєте доступ до відповідного Firebase проекту.
4.  **Запуск:** `flutter run`.

## 📈 Візуалізація даних
Для побудови графіків використовується бібліотека `fl_chart`, що дозволяє відображати історію показників сенсорів у зручному вигляді.

---
Документація створена для розробників та технічних спеціалістів, що працюють над проектом.
