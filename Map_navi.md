# План: «Указать на карте» — MapPickView

> **Статус**: реализация завершена (этапы 1–6), коммит `55427f7`.
> **Чтобы продолжить в следующей сессии**: скажи «продолжаем» — Claude прочитает этот файл и начнёт с раздела «Что осталось».

---

## Ключевое уточнение (важно для следующей сессии!)

**Часы пользователя подвязаны к телефону через Garmin Connect, и карты OSM уже скачаны на сами часы** (через Garmin Connect Mobile / Garmin Express по регионам).

Следствия для нашей реализации:
- `WatchUi.MapView` **читает локальные офлайн-карты с диска часов**, а не подгружает тайлы по BT.
- Карта рисуется мгновенно, без задержек на BT-канал, без «Loading…».
- Карта работает даже когда часы НЕ соединены с телефоном.
- Никакого расхода трафика.
- Та же картография OSM, что и в режиме активности (Run/Bike).

→ Риск №2 из ранней версии плана (медленный pan на BT) снят.
→ Permission `Communications` в манифесте **возможно не нужен** — см. открытый вопрос ниже.

---

## Context

В `navigation.md` пункт 8 «Указать на карте» был закрыт по Plan B (пункт скрыт через `Toybox has :Map`). Эта итерация реализует **Plan A** — нативный `Toybox.WatchUi.MapView`.

Дополнительное требование от пользователя: сенсорный экран **включён** в `MapPickView` и **выключен** при выходе. В терминах ConnectIQ: `MapPickDelegate ← BehaviorDelegate` обрабатывает touch; родительские делегаты (`TactixDelegate ← NoTouchDelegate`) восстанавливаются автоматически при `popView`.

---

## Архитектурные решения (зафиксированы)

| # | Решение | Обоснование |
|---|---------|-------------|
| 1 | API карты: `Toybox.WatchUi.MapView` | Тайлы из локальных офлайн-карт OSM на часах. |
| 2 | Все 6 устройств, основной UX — touch | У всех 6 целевых устройств есть сенсор. UP/DOWN/START — резерв (перчатки/вода). |
| 3 | Курсор-крест в центре + pan карты | Стандартный UX геокешеров; SELECT/tap → сохранить координаты центра. |
| 4 | Центр при открытии: текущая GPS-позиция | Без фикса показать `_NavMsgView "Нет GPS"` и не открывать карту. |
| 5 | `Toybox has :Map` guard остаётся | На устройствах без Map API пункт «Указать на карте» скрыт. |
| 6 | `NavManager` без изменений | `NavManager.add(lat, lon)` используется как есть (MAX=20). |

---

## Файлы (созданные/изменённые)

| Файл | Что в нём |
|------|-----------|
| `source/MapPickView.mc` | **новый**. `extends WatchUi.MapView`. Поля: `mCenterLat`, `mCenterLon`, `mAxisLat`, `mRadiusM=500`. Методы: `pan()`, `metersPerPixel()`, `_recenterMap()` (bbox SW/NE), `onUpdate()` (карта + overlay), `_shadowText()`. |
| `source/MapPickDelegate.mc` | **новый**. `extends BehaviorDelegate`. `onDrag` (START/CONTINUE/STOP → pan), `onPreviousPage` UP (+шаг), `onNextPage` DOWN (−шаг), `onMenu` START (toggle оси), `onSelect` (save), `onBack` (отмена). `_stepAxis(sign)` шаг 10% от радиуса. `_save()` → `NavManager.add` → `popView×3`. |
| `source/WaypointMenuDelegate.mc:56–66` | **изменён**. Пункт `:map` проверяет GPS-фикс и открывает `MapPickView` через `pushView(SLIDE_LEFT)`. |
| `manifest_clear.xml:25` | **изменён**. Добавлен `<iq:uses-permission id="Communications"/>` (под вопросом — см. ниже). |
| `CLAUDE.md` | **изменён**. Добавлены `MapPickView.mc` и `MapPickDelegate.mc` в таблицу навигационных модулей. |
| `navigation.md` | **изменён**. Раздел 8 (8.1–8.6) переписан как «Plan A реализован», ссылка на этот файл. |
| `deploy/store_description.txt` | **изменён**. Описан третий способ добавления метки (карта) на RU и EN. |

---

## Стадии реализации — все выполнены

| Этап | Статус | Что сделано |
|------|--------|-------------|
| 1. Каркас и заглушка | ✅ | `MapPickView` (рендер креста + координат), `MapPickDelegate` (заглушки), интеграция в WaypointMenu |
| 2. Нативная карта | ✅ | `extends MapView`, `MAP_MODE_BROWSE`, `setMapVisibleArea`, overlay поверх `super.onUpdate` |
| 3. Touch pan | ✅ | `onDrag` → конвертация pixels → degrees через `metersPerPixel()` и `cos(lat)` |
| 4. Кнопочный pan | ✅ | UP/DOWN ±50 м по оси, START → toggle оси, подсветка активной оси жёлтым |
| 5. Сохранение | ✅ | `_save()` → `NavManager.add` → `popView×3`, обработка MAX=20 |
| 6. Доки + коммит | ✅ | CLAUDE.md, navigation.md, store_description, коммит `55427f7` |

**Сборка**: все 6 устройств OK после каждого этапа (fenix8solar47mm, fenix8solar51mm, fenix847mm, epix2pro47mm, epix2pro42mm, fr265s).

---

## Что осталось (для следующей сессии)

### Открытые вопросы

1. **Permission `Communications` — убрать?**
   Раз карты офлайн на часах, MapView для чтения локальных тайлов разрешение на сеть не должен требовать. План: убрать `<iq:uses-permission id="Communications"/>` из `manifest_clear.xml`, пересобрать все 6 устройств. Если на каком-то устройстве MapView перестанет работать в симуляторе — вернуть обратно.

2. **Поведение `setMapVisibleArea` на реальных часах**.
   В симуляторе bbox ±500 м даёт разумный zoom, но на разных устройствах рендер может отличаться. Проверить, что начальный масштаб удобен пользователю (видны окрестные улицы при `mRadiusM = 500.0d`).

### Ручная проверка в симуляторе (e2e)

- [ ] **Сценарий E (touch)**: на fenix847mm запустить симулятор → двойной BACK → «Установить метку» → «Указать на карте» → видна карта, центр на GPS-симуляции → перетащить пальцем → координаты сверху обновились → SELECT → метка сохранена → проверить в «Удалить метку».
- [ ] **Сценарий F (кнопки)**: то же на fenix8solar47mm → проверить UP/DOWN/START.
- [ ] **Сценарий G (без GPS)**: отключить GPS в симуляторе → выбор «Указать на карте» → ожидаем `"Нет фикса GPS"`.
- [ ] **Сценарий H (touch enable/disable)**: после возврата с карты на главный циферблат — tap не реагирует (`TactixDelegate ← NoTouchDelegate`).

### Возможные доработки UX

- [ ] **Кнопки zoom**. Сейчас радиус видимой области фиксирован (500 м). Можно добавить zoom: например, длинное нажатие SELECT — переключение между 200/500/2000 м.
- [ ] **Подсказка для кнопочного управления**. Сейчас подсказка снизу — только `"SELECT — сохранить"`. Можно добавить вторую строку `"UP/DN — двигать  START — ось"` (опционально).
- [ ] **Возврат курсора на текущую позицию**. Кнопка «домой» (например, повторный START в LAT-режиме) — вернуть центр карты на текущую GPS.
- [ ] **Маркеры существующих меток**. Показывать на карте уже сохранённые waypoints через `setMapMarkers([...])`.

---

## Команды для быстрого старта

### Сборка всех 6 устройств
```bash
SDK=$(ls ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/ | grep connectiq-sdk-mac-9 | tail -1)
MONKEYC=~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/$SDK/bin/monkeyc
KEY=/Users/dim/garmin/clock/pilot/developer_key.der
JUNGLE=/Users/dim/garmin/clock/tactix/monkey_clear.jungle
BINDIR=/Users/dim/garmin/clock/tactix/bin

for D in fenix8solar47mm fenix8solar51mm fenix847mm epix2pro47mm epix2pro42mm fr265s; do
  "$MONKEYC" -f "$JUNGLE" -o "$BINDIR/SOFBlck_${D}.prg" -d "$D" -y "$KEY" \
    && echo "OK: $D" || echo "FAIL: $D"
done
```

### Деплой в симулятор
```bash
monkeydo bin/SOFBlck_fenix847mm.prg fenix847mm
```

### Просмотр коммитов навигации
```bash
git log --oneline --grep="MapPick\|навигаци\|Меню\|nav" -n 10
```

---

## Что НЕ входит в этот план (отвергнуто пользователем)

- Companion-приложение iOS/Android — отдельный проект на 2 платформы, недели работы.
- Скачивание тайлов через `Communications.makeImageRequest` — медленно по BT, лимит Storage ~128 KB, расход трафика. Не нужно, раз карты офлайн на часах.
- Изменение существующих делегатов компаса/будильника/таймера.

---

## Точки входа в код для следующей сессии

- Основная логика отрисовки карты: `source/MapPickView.mc`
- Логика ввода (touch + кнопки): `source/MapPickDelegate.mc`
- Точка входа из меню: `source/WaypointMenuDelegate.mc:56` (блок `if (id == :map)`)
- Хранение меток: `source/NavManager.mc` (MAX=20)
- Главный циферблат с пеленгом: `source/TactixApp.mc`, `source/TactixView.drawBearing()`
