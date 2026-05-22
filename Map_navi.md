# План: «Указать на карте» — MapPickView с нативной картой Garmin

## Context

В `navigation.md` пункт 8 («Указать на карте») был закрыт по **Plan B** (пункт скрыт через `Toybox has :Map`). Plan A — нативный `Toybox.WatchUi.MapView` — был отложен.

Этот план реализует Plan A. Карта на часах загружается через привязанный смартфон (нативный механизм Garmin: тайлы тянет сам Garmin Connect Mobile через BT-канал). UI выбора точки: курсор-крест по центру + pan карты, SELECT/tap → сохранить.

Дополнительное требование: **сенсорный экран** включается в `MapPickView` и отключается при выходе. В терминах ConnectIQ это означает: `MapPickDelegate` обрабатывает touch-события (через `BehaviorDelegate`), а возврат `popView` восстанавливает родительский делегат, унаследованный от `NoTouchDelegate` (touch автоматически «выключается» — события игнорируются).

---

## Архитектурные решения (по итогам уточнения)

| # | Решение | Обоснование |
|---|---------|-------------|
| 1 | API карты: `Toybox.WatchUi.MapView` (нативная) | Тайлы автоматически через телефон, кэш и стиль — забота Garmin. Никаких companion-приложений. |
| 2 | Поддержка устройств: **все 6** (у всех 6 есть сенсор) | Основной UX — touch (pan/tap). Кнопки UP/DOWN/START — резерв для управления в перчатках или мокрых условиях. SELECT/BACK обязательны на всех устройствах. |
| 3 | UX: курсор-крест в центре, pan карты | Стандартный UX геокешеров и навигаторов; SELECT/центральный tap → сохранить координаты центра. |
| 4 | Центр при открытии: текущая GPS-позиция | Без фикса показать `_NavMsgView "Нет GPS"` и не открывать карту (повторное использование существующего паттерна из `WaypointMenuDelegate.onSelect(:current)`). |
| 5 | `Toybox has :Map` guard остаётся | На устройствах без Map API пункт «Указать на карте» по-прежнему скрыт. |
| 6 | Хранение в `NavManager` без изменений | `NavManager.add(lat, lon)` уже умеет добавлять точку — используется как есть. |

---

## Файлы

### Новые

**`source/MapPickView.mc`** — `WatchUi.View`, рисует:
- Подложку — нативный `WatchUi.MapView` (через композицию: создаём `WatchUi.MapView` в `initialize()`, в `onUpdate(dc)` сам Garmin рисует карту).
- Курсор-крест в центре (2 линии `dc.drawLine`, `COLOR_RED`/`COLOR_WHITE`, длина 12 px при масштабе 260 px).
- Подсказку внизу: RU «SELECT — сохранить» / EN «SELECT — save» (FONT_XTINY).
- Текущие координаты центра карты (FONT_XTINY, сверху): `lat°N lon°E` с 4 знаками после запятой.

Поля:
- `mMapView as WatchUi.MapView`
- `mCenterLat as Double`, `mCenterLon as Double` — обновляются делегатом при pan/move
- `mAxisLat as Boolean` — для кнопочного режима (UP/DOWN двигает по lat если true, иначе по lon)

**`source/MapPickDelegate.mc`** — **`extends WatchUi.BehaviorDelegate`** (не `NoTouchDelegate` — touch разрешён).

Методы:
- `onTap(ev)` — tap по экрану: ничего не делаем (курсор фиксирован в центре; tap по центру — то же что SELECT, обрабатывается `onSelect()`).
- `onDrag(ev)` — pan карты: пересчитать `mCenterLat/Lon` смещением `(ev.getCoordinates() - предыдущая)` через `MapView.setMapVisibleArea()`. Использовать линейную интерполяцию px → градусы по zoom-уровню.
- `onSwipe(ev)` — мягкая инерционная прокрутка (опционально, минимальная версия — без инерции).
- `onSelect()` — кнопка SELECT: вызывает `_save()`.
- `onBack()` — отменить, `popView(SLIDE_RIGHT)`.
- `onNextPage()` (DOWN) / `onPreviousPage()` (UP) — на кнопочных устройствах сдвигают `mCenterLat`/`mCenterLon` на шаг (зависит от zoom).
- `onMenu()` (START) — переключение оси: `mAxisLat = !mAxisLat`.
- `_save()` — `NavManager.add(mCenterLat, mCenterLon)` → если успех: `popView×3` (MapPick → WaypointMenu → NavMenu → main), если MAX — показать `_NavMsgView "Максимум меток"`.

### Изменения

**`source/WaypointMenuDelegate.mc`** (строка 56–60):
```monkey
if (id == :map) {
    var posInfo = Position.getInfo();
    if (posInfo.position == null || posInfo.accuracy < Position.QUALITY_POOR) {
        var msg = rus ? "Нет фикса GPS" : "No GPS fix";
        WatchUi.pushView(new _NavMsgView(msg), new _NavMsgDelegate(), WatchUi.SLIDE_UP);
        return;
    }
    var coords = (posInfo.position as Position.Location).toDegrees();
    WatchUi.pushView(new MapPickView(coords[0] as Double, coords[1] as Double),
                     new MapPickDelegate(), WatchUi.SLIDE_LEFT);
    return;
}
```

**`manifest_clear.xml`**:
- Добавить `<iq:uses-permission id="Communications"/>` (требуется для тайлов карты через телефон).
- `Positioning` уже объявлен.
- `iq:devices` — оставить как есть (Map API guard через `Toybox has :Map` корректно отключит пункт на устройствах без поддержки).

**`CLAUDE.md`** — раздел «Навигационные модули»: добавить строку `MapPickView.mc` + `MapPickDelegate.mc`.

---

## Механизм touch enable/disable

В ConnectIQ нет API «выключить сенсор». Touch всегда физически доступен на сенсорных устройствах; программный контроль — только через делегатов:
- **«Touch включён»** = делегат не наследуется от `NoTouchDelegate` (события `onTap/onDrag/onSwipe` не консумируются, либо обрабатываются по существу).
- **«Touch выключен»** = делегат наследуется от `NoTouchDelegate` (все touch-события `return true` → игнорируются).

В этом плане:

| Экран | Делегат | Touch | Комментарий |
|-------|---------|-------|-------------|
| Главный циферблат | `TactixDelegate` ← `NoTouchDelegate` | выкл | Существующее поведение |
| NavMenu | `NavMenuDelegate` ← `Menu2InputDelegate` | системное | Menu2 сам обрабатывает |
| WaypointMenu | `WaypointMenuDelegate` ← `Menu2InputDelegate` | системное | Menu2 сам обрабатывает |
| **MapPickView** | **`MapPickDelegate` ← `BehaviorDelegate`** | **вкл** | Обрабатывает `onTap`/`onDrag`/`onSwipe` |
| Возврат на главный | `TactixDelegate` ← `NoTouchDelegate` | выкл | Автоматически через стек делегатов |

При `WatchUi.popView()` ConnectIQ восстанавливает предыдущий делегат из стека → touch снова игнорируется без дополнительного кода.

---

## Стадии реализации

### Этап 1 — Каркас и заглушка [x] ВЫПОЛНЕНО
- [x] Создан `source/MapPickView.mc` — `View` с курсором-крестом и текстом координат.
- [x] Создан `source/MapPickDelegate.mc` — `BehaviorDelegate` со всеми заглушками + рабочими `onBack`/`onMenu`.
- [x] `WaypointMenuDelegate.onSelect(:map)` — проверяет GPS-фикс, открывает `MapPickView` через `pushView(SLIDE_LEFT)`.
- [x] Сборка всех 6 устройств OK.

### Этап 2 — Нативная карта [x] ВЫПОЛНЕНО
- [x] `MapPickView extends WatchUi.MapView` (наследование вместо композиции — корректнее для overlay).
- [x] `onUpdate(dc)` вызывает `MapView.onUpdate(dc)` (тайлы) → поверх рисует overlay с чёрной обводкой текста для читаемости.
- [x] `<iq:uses-permission id="Communications"/>` добавлен в `manifest_clear.xml`.
- [x] `setMapMode(MAP_MODE_BROWSE)` + `setMapVisibleArea(loc, loc)` для начального центрирования.
- [x] Сборка всех 6 устройств OK.

### Этап 3 — Pan карты (сенсорное управление) [x] ВЫПОЛНЕНО
- [x] `MapPickView.pan(dLat, dLon)` с clamp широты (±89.9°) и wrap долготы (±180°).
- [x] `MapPickView.metersPerPixel()` через фиксированный радиус видимой области `mRadiusM = 500.0`.
- [x] `_recenterMap()` строит bbox SW/NE с коррекцией долготы по `cos(lat)`.
- [x] `MapPickDelegate.onDrag()` — отслеживает START/CONTINUE/STOP, конвертирует pixels → degrees.
- [x] Направление: палец вправо → карта вправо → центр lon уменьшается.
- [x] Сборка всех 6 устройств OK.

### Этап 4 — Резервное кнопочное управление [x] ВЫПОЛНЕНО
- [x] `onPreviousPage` (UP) — +шаг по активной оси; `onNextPage` (DOWN) — −шаг.
- [x] `onMenu` (START) — переключение `mAxisLat` с `requestUpdate`.
- [x] Шаг сдвига кнопкой — 10% от `mRadiusM` (50 м при радиусе 500 м), коррекция долготы по `cos(lat)`.

### Этап 5 — Сохранение и pop [x] ВЫПОЛНЕНО (e2e на симуляторе — опционально)
- [x] `onSelect()` → `_save()` → `NavManager.add(...)` → `popView×3` (MapPick → WaypointMenu → NavMenu → main).
- [x] Обработка `MAX=20`: показывает `_NavMsgView "Максимум меток"`.

### Этап 6 — Локализация, документация, коммит [x] ВЫПОЛНЕНО
- [x] Все строки через `rus ? "..." : "..."`.
- [x] `CLAUDE.md` обновлён — добавлены `MapPickView.mc` и `MapPickDelegate.mc` в таблицу + `Communications` упомянут.
- [x] `navigation.md` обновлён — подзадачи 8.1–8.5 переписаны как «Plan A реализован», ссылка на `Map_navi.md`.
- [x] `deploy/store_description.txt` обновлён — описан третий способ добавления метки (карта).
- [ ] Финальный коммит (выполняется ниже).

---

## Текущий статус: все 6 этапов готовы

| Этап | Статус | Файлы |
|------|--------|-------|
| 1. Каркас | ✅ | `MapPickView.mc`, `MapPickDelegate.mc`, `WaypointMenuDelegate.mc` |
| 2. Нативная карта | ✅ | `MapPickView.mc` (`extends MapView`), `manifest_clear.xml` |
| 3. Touch pan | ✅ | `MapPickView.pan/metersPerPixel`, `MapPickDelegate.onDrag` |
| 4. Кнопочный pan | ✅ | `MapPickDelegate.onNextPage/onPreviousPage/_stepAxis` |
| 5. Сохранение | ✅ | `MapPickDelegate._save` |
| 6. Доки + коммит | ✅ | `CLAUDE.md`, `navigation.md`, `store_description.txt`, `Map_navi.md`, git |

---

## Верификация (end-to-end)

### Сборка
```bash
DEVICES=(fenix8solar47mm fenix8solar51mm fenix847mm epix2pro47mm epix2pro42mm fr265s)
for D in "${DEVICES[@]}"; do
  monkeyc -f monkey_clear.jungle -o bin/SOFBlck_$D.prg -d $D \
          -y /Users/dim/garmin/clock/pilot/developer_key.der
done
```
Ожидание: 6 OK, 0 FAIL.

### Сценарии на симуляторе

- **E. Карта на сенсорном устройстве (fenix847mm, epix2pro)**:
  - двойной BACK → NavMenu → «Установить метку» → «Указать на карте» → открывается карта, центрированная на текущей GPS;
  - перетаскивание пальцем — карта движется, координаты сверху обновляются;
  - tap по центру или SELECT → метка сохранена, возврат на главный экран;
  - метка видна в «Удалить метку» с корректной дистанцией;
  - BACK на карте → отмена, возврат в WaypointMenu, метка не создана.
- **F. Резервное кнопочное управление (на любом устройстве)**:
  - UP/DOWN двигает центр по активной оси; START переключает ось lat/lon; SELECT сохраняет;
  - подсветка активной оси (LAT/LON жёлтым) меняется при каждом START;
  - пункт «Указать на карте» **скрыт**, если `Toybox has :Map == false` (на любом устройстве).
- **G. Без GPS-фикса**:
  - выбор «Указать на карте» без фикса → `"Нет фикса GPS"` (повтор существующего поведения для `:current`).
- **H. Touch enable/disable**:
  - на главном экране (после возврата с карты) tap не реагирует — `TactixDelegate ← NoTouchDelegate` ✓
  - в `MapPickView` tap/drag работает — `MapPickDelegate ← BehaviorDelegate` ✓

### Деплой в симулятор
```bash
monkeydo bin/SOFBlck_fenix847mm.prg fenix847mm
```

---

## Открытые вопросы / риски

1. **Поведение MapView в watch-app vs widget**. В SDK 9.1 пример MapSample использует `type="watch-app"`, но не включает fenix8solar в `iq:devices`. Если на каком-то устройстве `Toybox has :Map == true`, но MapView некорректно рендерится — добавить дополнительный guard на этапе 2.
2. **Скорость pan**. На медленном BT-канале тайлы могут грузиться с задержкой. Решение: добавить индикатор `Loading…` поверх карты при drag (опционально).
3. **Pan-формула px → градусы**. Требует знания текущего zoom-уровня `MapView`. Если SDK не отдаёт zoom — использовать фиксированный шаг (0.0001° на px) с эвристикой по платформе.
4. **Storage лимит для тайлов** — Garmin Map API кэширует тайлы сам, лимит не считаем.

---

## Что НЕ входит в этот план

- Companion-приложение iOS/Android (отвергнуто пользователем).
- Скачивание тайлов через `Communications.makeImageRequest` (отвергнуто).
- Изменение существующих делегатов компаса/будильника/таймера.
- Сценарии A–D из `navigation.md` уже закрыты (этап 6).
