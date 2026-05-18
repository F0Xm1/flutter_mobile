# Чіпідізєль — Дизайн-документ

Опис візуального дизайну, компонентів, кольорів та інтерактивних патернів мобільного додатку.

---

## 1. Загальна концепція

Темна тема з акцентним фіолетовим кольором. Стиль — glass-morphism: напівпрозорі картки з кольоровими рамками поверх темного градієнтного фону. Усі екрани побудовані на одній колірній базі, тому інтерфейс виглядає єдино навіть при переході між сторінками.

---

## 2. Кольорова палітра

| Назва | HEX / Flutter | Застосування |
|---|---|---|
| Dark Background | `#1A1B2D` | Фон усіх екранів, AppBar |
| Secondary Background | `#25274D` | Bottom sheets, dropdown, overlay |
| Accent Purple | `#8A2BE2` | Основні кнопки, TabBar indicator, RefreshIndicator |
| Light Purple | `#B19CD9` | Декоративне коло на екрані авторизації |
| Green Accent | `Colors.greenAccent` | Статус "Онлайн", нормальна картка сенсора |
| Red Accent | `Colors.redAccent` | Перевищення порогу, видалення, лінія max-порогу |
| Blue Accent | `Colors.blueAccent` | Нижче мінімального порогу, лінія min-порогу |
| Teal Accent | `Colors.tealAccent` | Акцент на сторінці сенсорів (іконки локацій, кнопки) |
| Orange | `Colors.orange` | Попередження (бекенд офлайн), банер lastAlert |
| Amber | `Colors.amber.shade700` | Банер офлайн-режиму |
| White | `Colors.white` з alpha | Текст: 100% — основний, 60% — підписи, 38% — вторинний, 24% — роздільники |

### Градієнти

**Фон (усі сторінки крім авторизації):**
```
LinearGradient: #1A1B2D → #25274D
Напрямок: Alignment.topCenter → Alignment.bottomCenter
```

**Фон авторизації:**
```
LinearGradient: #1A1B2D → #25274D
Напрямок: Alignment.topLeft → Alignment.bottomRight
```

---

## 3. Типографіка

| Роль | Розмір | Вага | Колір |
|---|---|---|---|
| Заголовок авторизації | 32px | bold | white |
| Підзаголовок авторизації | 16px | regular | grey |
| Заголовок bottom sheet | 18px | bold | white |
| Значення телеметрії (велике) | 52px | bold | white |
| Значення в картці сенсора | 24px | bold | white / redAccent |
| Значення в картці події | 22px | bold | redAccent / blueAccent |
| Назва локації | regular | w600 | white |
| Підпис/мітка | 12–13px | regular | white54–white60 |
| Вторинний текст | 11–12px | regular | white38 |

---

## 4. Форми та закруглення

| Елемент | border-radius |
|---|---|
| Картки сенсорів (`SensorCard`) | 16px |
| Картки подій (`_EventCard`) | 14px |
| Картки локацій (`_LocationTile`) | 14px |
| Bottom sheets | 20px (верхні кути) |
| Кнопки (основні) | 12px |
| Кнопки навігації на дашборді | 14px |
| Статус-чіп (`BackendStatusWidget`) | 20px (pill) |
| Поля вводу | 12px |
| Форма авторизації (контейнер) | 16px |

---

## 5. Екрани

### 5.1. Авторизація (LoginPage / RegisterPage)

**Фон:**
- Діагональний градієнт `#1A1B2D → #25274D`
- Два декоративних кола поза видимою областю:
  - Верхній лівий кут: `radius 100`, `#B19CD9` з opacity 30%
  - Нижній правий: `radius 125`, `#8A2BE2` з opacity 20%

**Форма:**
- Центрована по вертикалі (`SingleChildScrollView + Center`)
- Горизонтальні відступи: 24px
- Заголовок + підзаголовок
- Блок полів вводу — контейнер з `Colors.white` 10% alpha, `borderRadius 16`, padding 16
- Поля `ReusableTextField`: темний фон (5% white), рамка 20% white, фокус — tealAccent
- Кнопка "Увійти" — повна ширина, `#8A2BE2`, висота 52px (вертикальний padding 16)
- При `AuthLoading` — кнопка замінюється `CircularProgressIndicator`
- Кнопка Google — біла кнопка з чорним текстом, `Icons.g_mobiledata`
- Розділювач "або" — дві лінії по 60px з текстом по центру
- Посилання "Зареєструватися" — underline, bold white

**Помилки:**
- `AuthError` → червоний текст між кнопками

---

### 5.2. Дашборд (HomePage + HomeContent)

**AppBar:**
- Фон `#1A1B2D`, текст/іконки білі
- Title: якщо одна локація — `Text`; якщо кілька — `DropdownButton` (фон `#25274D`, стиль 18px w500)
- Action: іконка виходу `Icons.exit_to_app`

**Body:**
- `Stack`: градієнтний фон + `SafeArea(HomeContent)`
- `HomeContent` → `BlocBuilder<DashboardCubit>`

**Офлайн-банер** (якщо `isFromCache == true`):
- Повна ширина, колір `Colors.amber.shade700`
- Іконка `Icons.wifi_off`, текст "Офлайн — показуємо останні відомі дані", 13px w600, чорний
- Не скролиться — закріплений зверху

**Контент (скролиться):**
- Padding: `fromLTRB(16, 12, 16, 24)`
- `BackendStatusWidget` — pill-чіп зі статусом симулятора
- `lastAlert` банер (якщо є) — помаранчевий контейнер, `borderRadius 12`, border 40% orange
- Два `SensorCard` в ряд (Температура + Вологість) з проміжком 12px
- `SensorCard` Тиск — на всю ширину
- Три кнопки навігації: Телеметрія, Журнал подій, Сенсори

**SensorCard:**
```
Нормальний стан:    фон greenAccent 15%, рамка greenAccent 40%
Перевищення порогу: фон red 22%, рамка redAccent 60%
```
- Верхній рядок: іконка (white60, 18px) + назва (white60, 13px) + `Icons.warning_amber` при перевищенні
- Значення: `AnimatedSwitcher` 350ms з FadeTransition + SlideTransition (slide знизу)
  - Є значення: 24px bold, white або redAccent
  - Немає даних: "— {unit}", white30

**Кнопки навігації:**
- `ElevatedButton.icon`, фон `#8A2BE2`, padding vertical 16, borderRadius 14
- Повна ширина, іконка + текст 16px bold white

---

### 5.3. Телеметрія (TelemetryPage)

**AppBar:**
- Кнопки праворуч: `Icons.file_download_outlined` (CSV-експорт), `Icons.tune` (пороги)
- `TabBar` внизу AppBar: labelColor white, unselected white54, indicator `#8A2BE2`
- Вкладки генеруються динамічно з БД (temperature → humidity → pressure)

**Вміст вкладки:**
- Padding 16px з усіх сторін
- Поточне значення великим шрифтом: 52px bold white
- Назва типу: 16px white54
- `TelemetryChartWidget` — займає весь простір що залишився (`Expanded`)

**TelemetryChartWidget:**
| Тип (одиниця) | Колір лінії |
|---|---|
| Температура (°C) | `Colors.redAccent` |
| Вологість (%) | `Colors.blueAccent` |
| Тиск (hPa) | `Colors.greenAccent` |

- Заливка під лінією: колір лінії з alpha 15%
- Ліва вісь: значення + одиниця, white60, 10px
- Рамка: `Colors.white24`
- Точки на лінії вимкнені
- Лінії порогів: пунктирні `[6, 4]`, red (max) / blue (min), з мітками
- Tooltip: чорний фон `Colors.black87`, значення 2 знаки + одиниця
- Анімація оновлення: 300ms

**Bottom sheet налаштування порогів:**
- Системна тема (білий фон), поля вводу зі стандартним оформленням теми
- Два поля: Мінімум / Максимум з підказкою одиниці
- Кнопка "Зберегти" — повна ширина, тема Material

**Bottom sheet CSV-експорту:**
- Фон `#25274D`, borderRadius 20px верхні кути
- Заголовок 18px bold + підзаголовок 13px white54
- Два `OutlinedButton` в ряд: "Від: DD.MM.YYYY" / "До: DD.MM.YYYY"
  - Рамка white38, borderRadius 10, двострочний контент (мітка + дата)
- Кнопка "Експортувати" — `#8A2BE2`, висота 48px, borderRadius 12
- Під час завантаження: кнопка замінюється `CircularProgressIndicator` 20×20

---

### 5.4. Журнал подій (EventsPage)

**AppBar:** стандартний, заголовок "Журнал подій"

**Список:**
- `RefreshIndicator`: колір `#8A2BE2`, фон `#25274D`
- Padding: `fromLTRB(12, 12, 12, 24)`
- Порожній стан: центрований текст "Порогів ще не було перевищено", white54

**_EventCard:**
| Тип | Фон | Рамка | Акцент |
|---|---|---|---|
| max (перевищення) | red 15% alpha | redAccent 45% | `Colors.redAccent` |
| min (нижче мінімуму) | blue 15% alpha | blueAccent 45% | `Colors.lightBlueAccent` |

- Структура: іконка ліворуч (30px, white60) + колонка по центру + час праворуч
- Іконки: `Icons.thermostat` / `Icons.water_drop` / `Icons.speed`
- Колонка: тип (12px white54) → значення (22px bold, акцентний колір) → опис порогу (12px white38)
- Час (відносний): "щойно" / "N хв тому" / "N год тому" / "DD.MM HH:MM"
- Відступ між картками: 10px
- BorderRadius: 14px

---

### 5.5. Управління сенсорами (SensorsPage)

**AppBar:** кнопка `+` праворуч для додавання локації

**Порожній стан:**
- Іконка `Icons.location_off_outlined` 72px white24
- Текст 18px white54
- `OutlinedButton.icon` з tealAccent рамкою та іконкою

**_LocationTile:**
- `Dismissible` (swipe ліворуч): червоний фон з `Icons.delete_outline` redAccent
- Контейнер: white 5% alpha, border white 8% alpha, borderRadius 14px
- `ExpansionTile` всередині:
  - Іконка: `Icons.location_on_outlined` tealAccent
  - Назва: white w600
  - Адреса: white38 12px (якщо є)
  - Іконка стрілки: згорнуто white38, розгорнуто white60
- Підтвердження видалення: `AlertDialog` з фоном `#25274D`

**_SensorTile (всередині ExpansionTile):**
- `Dismissible` (swipe ліворуч): `Icons.delete_outline` redAccent
- `ListTile`: padding horizontal 20px
  - Іконка: tealAccent 70% alpha, 22px
  - Назва: white 14px
  - Підназва: тип (white38 12px)
  - Trailing: одиниця white54 13px

**Bottom sheet додавання локації:**
- Фон `#25274D`, borderRadius 20px верхні кути
- `_DarkTextField` × 2 (Назва, Адреса)
- Кнопка "Додати" — teal, borderRadius 12

**Bottom sheet додавання сенсора:**
- Додатково: `DropdownButtonFormField` (фон `#1A1B2D`, тема темна)
- Блок з одиницею: тільки читання, білий напівпрозорий контейнер, одиниця tealAccent bold

**_DarkTextField:**
- Заповнення: white 5% alpha
- Рамка: white 20% normal, tealAccent при фокусі
- Текст: white, мітка: white54

---

## 6. Інтерактивні патерни

### Swipe-to-delete
Застосовується на `_LocationTile` та `_SensorTile`.
- Напрямок: `endToStart` (праворуч ліворуч)
- Фон: червоний контейнер з іконкою кошика
- Обов'язкове підтвердження через `AlertDialog` перед видаленням

### Pull-to-refresh
Застосовується на `EventsPage` та `SensorsPage`.
- `RefreshIndicator`: колір `#8A2BE2`, фон `#25274D`

### Bottom sheets
Усі bottom sheets — `showModalBottomSheet(isScrollControlled: true)`.
Адаптуються до клавіатури через `MediaQuery.viewInsetsOf(context).bottom`.

| Bottom sheet | Тригер | Колір фону |
|---|---|---|
| Налаштування порогів | Іконка `tune` в AppBar | Системна тема |
| Експорт CSV | Іконка `file_download_outlined` | `#25274D` |
| Додати локацію | Кнопка `+` в AppBar | `#25274D` |
| Додати сенсор | Кнопка "Додати сенсор" в LocationTile | `#25274D` |

### Вибір дати
`showDatePicker` з кастомною темою:
```
ColorScheme.dark(
  primary: #8A2BE2,
  surface: #25274D,
)
```

### Стан завантаження
Скрізь єдиний підхід: `CircularProgressIndicator(color: Colors.white)` у центрі екрана або `SizedBox(20×20)` всередині кнопки з `strokeWidth: 2`.

---

## 7. Навігація

```
/  ────────────────────────── AuthGuard
      │                            │
      ▼ є сесія               ▼ немає
   /home                      /login ──── /register
      │                            │
      ├── /telemetry ◄─────────────┘ (через кнопку "Телеметрія")
      ├── /events
      └── /sensors
```

- Усі переходи через `Navigator.pushNamed`
- Логін → хом: `pushNamedAndRemoveUntil` (очищає стек)
- Вихід → логін: `pushReplacementNamed`
- Перехід на `/telemetry` передає `Map<String, String?> {locationId, locationName}`

---

## 8. Анімації

| Елемент | Анімація | Тривалість |
|---|---|---|
| `SensorCard` значення | `AnimatedSwitcher`: FadeTransition + SlideTransition (Offset 0,0.3 → 0,0) | 350ms |
| `TelemetryChartWidget` | Вбудована анімація `LineChart` | 300ms |
| `BackendStatusWidget` | Перерендер кожну секунду через `Timer.periodic` | — |

---

## 9. Стан-залежний вигляд

### SensorCard
| Стан | Фон | Рамка | Колір значення |
|---|---|---|---|
| Немає даних | greenAccent 15% | greenAccent 40% | white30 |
| Норма | greenAccent 15% | greenAccent 40% | white |
| Перевищення | red 22% | redAccent 60% | redAccent + іконка warning |

### BackendStatusWidget
| Стан | Колір | Іконка |
|---|---|---|
| Немає даних (null) | orange | `warning_amber_rounded` |
| Стале > 30 с | orange | `warning_amber_rounded` |
| Онлайн (< 30 с) | greenAccent | `circle` |

### Офлайн-банер (HomePage)
| `isFromCache` | Відображення |
|---|---|
| `false` | Банер прихований |
| `true` | Жовтий банер: amber.shade700, "Офлайн — показуємо останні відомі дані" |

### EventCard
| `threshold_type` | Фон | Рамка | Акцент |
|---|---|---|---|
| `max` | red 15% | redAccent 45% | redAccent |
| `min` | blue 15% | blueAccent 45% | lightBlueAccent |
