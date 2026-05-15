# Чіпідізєль — Smart Telemetry System

Flutter-додаток для моніторингу телеметрії (температура, вологість, тиск) із датчиків у реальному часі через Supabase Realtime.

## Функціонал

- Realtime-графіки телеметрії (температура / вологість / тиск)
- Налаштування порогів (мін/макс) для кожного сенсора
- Локальні сповіщення при перевищенні порогів (cooldown 30 с)
- Візуальна індикація порогів на графіку
- Авторизація (email/password + Google OAuth)
- Блокування UI при відсутності мережі

## Стек

- **Flutter** — мобільний застосунок
- **Supabase** — PostgreSQL + Realtime + Auth
- **Firebase Cloud Messaging** — push-сповіщення
- **flutter_local_notifications** — локальні порогові нотифікації
- **fl_chart** — графіки телеметрії
- **.NET** — симулятор сенсорів + MQTT listener (окремий репозиторій)

## Швидкий старт

```bash
# Залежності
flutter pub get

# .env у корені проекту
SUPABASE_URL=https://unjpmqtykfsywbvnrnry.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SENSOR_ID_TEMPERATURE=08769695-abd6-48de-a5b6-f2b9f3e2dc74
SENSOR_ID_HUMIDITY=8f9c6a83-f16b-4ffa-ae5b-5495271f16df
SENSOR_ID_PRESSURE=237d9612-a86d-437e-a118-d0bf5bfc6833

# Міграції Supabase
supabase db push

# Запуск
flutter run
```

## Документація

- [DOCUMENTATION.md](./DOCUMENTATION.md) — огляд модулів, структура, налаштування
- [TECHNICAL_SPEC.md](./TECHNICAL_SPEC.md) — архітектура, потоки даних, схема БД
