# План реализации: Секундомер и Таймер для Tactix

> Документ описывает добавление режимов секундомера и таймера в приложение
> `tactix_clear` (`type="watchApp"`). План разбит на независимые задачи для
> параллельного выполнения несколькими агентами в нескольких сессиях.

## Статус

- [x] Волна 1 завершена
- [x] Волна 2 завершена
- [x] Волна 3 завершена
- [x] Финальная интеграция: сборка `tactix_clear.prg` для fenix8solar47mm
  проходит без ошибок (verified 2026-05-18)
- [ ] Приёмочное тестирование на симуляторе/устройстве (раздел 6)
- [ ] Открытые вопросы раздела 7 (вибрация при истечении — реализована;
  остальные пункты — требуют решения)

---

## 1. Цели

- Двойное нажатие BACK на главном экране → отдельный экран секундомера
- Двойное нажатие DOWN на главном экране → отдельный экран таймера
- Когда таймер или секундомер активны, их состояние отображается на главном
  экране в области будильника поверх стрелок
- Приоритет на главном экране: **таймер > секундомер > будильник**

---

## 2. Текущее состояние (уже сделано)

- [x] `TactixApp` хранит состояние секундомера: `swRunning`, `swStartMs`, `swOffsetMs`
- [x] `TactixApp.toggleStopwatch()`, `TactixApp.getSwElapsedMs()`
- [x] `TactixView` рисует overlay секундомера поверх стрелок синим, формат
  `ЧЧ:ММ:СС`, 7-сегментный шрифт
- [x] `TactixView` обновляется раз в секунду через `Timer.Timer` в `onShow()`
- [x] `TactixView extends WatchUi.View` (не `WatchFace`)
- [x] `TactixDelegate extends BehaviorDelegate`, обрабатывает `onBack()` с
  отслеживанием двойного нажатия (порог 500 мс)
- [x] `manifest_clear.xml`: `type="watchApp"`

---

## 3. Архитектура

### 3.1 Файлы

**Изменяемые:**
- `source/TactixApp.mc` — добавить состояние таймера, методы сброса
- `source/TactixView.mc` — перенести таймер из `drawCenterTexts` в overlay поверх
  стрелок, добавить приоритет
- `source/TactixDelegate.mc` — заменить toggle на pushView; добавить обработку
  DOWN

**Новые:**
- `source/StopwatchView.mc`
- `source/StopwatchDelegate.mc`
- `source/TimerView.mc`
- `source/TimerDelegate.mc`

### 3.2 Контракт TactixApp (зафиксирован, не меняется в ходе работы)

```monkeyc
class TactixApp extends Application.AppBase {
    // --- Секундомер ---
    var swRunning  as Boolean;
    var swStartMs  as Number;     // System.getTimer() в момент старта
    var swOffsetMs as Number;     // накопленные мс до текущего старта

    function toggleStopwatch() as Void;        // старт/пауза
    function resetStopwatch()  as Void;        // полный сброс к нулю + стоп
    function getSwElapsedMs()  as Number;      // прошедшее в мс (с учётом running)
    function hasStopwatch()    as Boolean;     // swRunning ИЛИ swOffsetMs > 0

    // --- Таймер обратного отсчёта ---
    var tRunning   as Boolean;
    var tStartMs   as Number;     // System.getTimer() в момент последнего старта
    var tRemainMs  as Number;     // оставшееся ms на момент последней паузы

    function startTimer(durationMs as Number) as Void;   // установить и запустить
    function toggleTimerPause()           as Void;       // пауза/возобновить
    function resetTimer()                 as Void;       // полный сброс + стоп
    function getTimerRemainingMs()        as Number;     // оставшееся в мс
    function hasTimer()                   as Boolean;    // tRunning ИЛИ tRemainMs > 0
}
```

### 3.3 Контракт расчёта времени

Все расчёты через **`System.getTimer()`** (мс с момента включения устройства):

```
swElapsed  = swRunning  ? swOffsetMs + (System.getTimer() - swStartMs) : swOffsetMs
tRemaining = tRunning   ? max(0, tRemainMs - (System.getTimer() - tStartMs)) : tRemainMs
```

### 3.4 Маршрутизация на главном экране

- BACK × 2 (≤500 мс) → `WatchUi.pushView(new StopwatchView(), new StopwatchDelegate(), WatchUi.SLIDE_LEFT)`
- DOWN × 2 (≤500 мс) → `WatchUi.pushView(new TimerView(), new TimerDelegate(), WatchUi.SLIDE_LEFT)`

Одиночные нажатия — поглощаются (без действия).

### 3.5 Установка времени таймера (когда `!app.hasTimer()`)

Простая модель — три поля редактирования (ч / м / с):
- `UP`     — увеличить значение текущего поля
- `DOWN`   — уменьшить значение текущего поля
- `LIGHT`  — переключить поле (ч → м → с → ч)
- `SELECT` (START) — `app.startTimer(durationMs)`
- `BACK`   — `popView()` без старта

---

## 4. Задачи (декомпозиция для параллельных агентов)

### Волна 1 — фундамент (1 задача)

#### Задача 1: TactixApp — добавить состояние таймера и расширить секундомер
- **Файл:** `source/TactixApp.mc`
- **Агент:** `backend-state`
- **Зависимости:** нет
- **Блокирует:** Задачи 2, 4, 6

Чек-лист:
- [ ] Добавить переменные: `tRunning`, `tStartMs`, `tRemainMs` с инициализацией нулями/false
- [ ] Реализовать `startTimer(durationMs)`: сохранить `tRemainMs = durationMs`,
  `tStartMs = System.getTimer()`, `tRunning = true`
- [ ] Реализовать `toggleTimerPause()`: если running → зафиксировать `tRemainMs -=
  elapsed`, `tRunning = false`; иначе → `tStartMs = System.getTimer()`, `tRunning = true`
- [ ] Реализовать `resetTimer()`: всё в ноль/false
- [ ] Реализовать `getTimerRemainingMs()` согласно п. 3.3 (никогда не < 0)
- [ ] Реализовать `hasTimer()` (см. контракт)
- [ ] Добавить `resetStopwatch()` — обнулить `swStartMs`, `swOffsetMs`, `swRunning=false`
- [ ] Добавить `hasStopwatch()`
- [ ] Не ломать `toggleStopwatch()`, `getSwElapsedMs()` (уже работают)

Готовность: файл компилируется отдельно, методы соответствуют контракту 3.2.

---

### Волна 2 — экраны и главный overlay (3 задачи параллельно)

#### Задача 2: StopwatchView — отдельный экран секундомера
- **Файл:** `source/StopwatchView.mc` (новый)
- **Агент:** `ui-stopwatch`
- **Зависимости:** Задача 1 (для `hasStopwatch()`)
- **Конфликты:** нет (новый файл)

Чек-лист:
- [ ] `class StopwatchView extends WatchUi.View`
- [ ] Поле `mTimer as Timer.Timer?`
- [ ] `onShow()` — создать и запустить `Timer.Timer.start(method(:onTick), 40, true)`
- [ ] `onHide()` — `mTimer.stop()`, `mTimer = null` (очистка ресурсов)
- [ ] `onTick()` — `WatchUi.requestUpdate()`
- [ ] `onUpdate(dc)`:
  - [ ] Чёрный фон (прозрачным быть не может — это отдельный экран): `dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK); dc.clear();`
  - [ ] Прочитать `app.getSwElapsedMs()`
  - [ ] Разбить на `hh`, `mm`, `ss`, `cs` (cs = `(ms % 1000) / 10`)
  - [ ] Сформировать строку `Lang.format("$1$:$2$:$3$:$4$", [hh.format("%02d"), mm.format("%02d"), ss.format("%02d"), cs.format("%02d")])`
  - [ ] Нарисовать по центру синим (`Graphics.COLOR_BLUE`) электронным шрифтом
  - [ ] Использовать `Graphics.FONT_NUMBER_MEDIUM` или подобный (электронный вид)
- [ ] Если нет состояния — показывает `00:00:00:00`

Готовность: при открытии видна ЧЧ:ММ:СС:сс синим, обновляется 25 раз в секунду.

#### Задача 4: TimerView — отдельный экран таймера с установкой времени
- **Файл:** `source/TimerView.mc` (новый)
- **Агент:** `ui-timer`
- **Зависимости:** Задача 1 (для `hasTimer()`, `getTimerRemainingMs()`)
- **Конфликты:** нет (новый файл)

Чек-лист:
- [ ] `class TimerView extends WatchUi.View`
- [ ] Поля: `mTimer as Timer.Timer?`, `mSetupMode as Boolean`, `mSetHours/Min/Sec as Number`, `mSetupField as Number` (0=h,1=m,2=s)
- [ ] Публичные сеттеры для использования из делегата (или public-поля): инкремент/декремент текущего поля, переключение поля
- [ ] Метод `getSetupDurationMs() as Number` — вернуть установленное время в мс
- [ ] `onShow()`:
  - [ ] `mSetupMode = !app.hasTimer()`
  - [ ] Если setup — обнулить поля установки в значения по умолчанию (например, 0:05:00)
  - [ ] `mTimer.start(method(:onTick), 1000, true)`
- [ ] `onHide()` — стоп и `null`
- [ ] `onTick()` — `WatchUi.requestUpdate()`
- [ ] `onUpdate(dc)`:
  - [ ] Чёрный фон + `dc.clear()`
  - [ ] `mSetupMode == true`:
    - Показать `HH:MM:SS` красным
    - Курсор/подсветка под текущим полем (`mSetupField`)
    - Подсказка снизу: "UP/DOWN — value, LIGHT — field, START — go"
  - [ ] `mSetupMode == false`:
    - Прочитать `app.getTimerRemainingMs()`
    - Если 0 — показать `00:00:00`
    - Показать `ЧЧ:ММ:СС` красным (`Graphics.COLOR_RED`)
- [ ] `Lang.format()` + `format("%02d")` для всех цифр

Готовность: открывается с UI установки если таймера нет; иначе показывает обратный отсчёт.

#### Задача 6: TactixView — перенести таймер в overlay, ввести приоритет
- **Файл:** `source/TactixView.mc`
- **Агент:** `ui-main`
- **Зависимости:** Задача 1 (для `app.hasTimer()`, `app.hasStopwatch()`)
- **Конфликты:** нет (другие агенты не трогают этот файл в Волне 2)

Чек-лист:
- [ ] Из `drawCenterTexts` удалить ветку с `tRunning` (`Application.Storage`) —
  таймер больше не рисуется под стрелками. В `drawCenterTexts` остаётся только
  будильник (`drawAlarmArea`).
- [ ] Удалить метод `drawTimerArea` (он рисовал под стрелками)
- [ ] Удалить вызов `drawStopwatchOverlay` после `drawHands` (заменяется на
  новый метод с приоритетами)
- [ ] Добавить новый метод `drawStatusOverlay(dc, cx, cy)`:
  ```
  var app = Application.getApp() as TactixApp;
  if (app.hasTimer())      { drawTimerOverlay(dc, cx, cy); return; }
  if (app.hasStopwatch())  { drawStopwatchOverlayInner(dc, cx, cy); return; }
  // иначе — alarm уже нарисован в drawCenterTexts
  ```
- [ ] `drawTimerOverlay`: "T" + ЧЧ:ММ:СС из `app.getTimerRemainingMs()`, цвет
  `Graphics.COLOR_RED`, тот же 7-сегментный `drawSegText` на месте будильника
- [ ] `drawStopwatchOverlayInner`: "S" + ЧЧ:ММ:СС из `app.getSwElapsedMs()`,
  цвет `Graphics.COLOR_BLUE`, на месте будильника (логика существующего
  `drawStopwatchOverlay`)
- [ ] В `onUpdate` после `drawHands` вызвать `drawStatusOverlay(dc, cx, cy)`
- [ ] Когда секундомер активен и зашёл таймер — таймер имеет приоритет

Готовность: при активном таймере красное ЧЧ:ММ:СС поверх стрелок; при активном
секундомере синее ЧЧ:ММ:СС поверх стрелок; иначе будильник под стрелками.

---

### Волна 3 — делегаты ввода (3 задачи параллельно)

#### Задача 3: StopwatchDelegate — обработка кнопок на экране секундомера
- **Файл:** `source/StopwatchDelegate.mc` (новый)
- **Агент:** `input-stopwatch`
- **Зависимости:** Задача 2 (StopwatchView существует), Задача 1 (app методы)
- **Конфликты:** нет

Чек-лист:
- [ ] `class StopwatchDelegate extends WatchUi.BehaviorDelegate`
- [ ] `onSelect() as Boolean` (START/STOP):
  - `app.toggleStopwatch()`, `WatchUi.requestUpdate()`, return `true`
- [ ] `onNextPage() as Boolean` (DOWN, при наличии) ИЛИ `onKey(WatchUi.KEY_DOWN)`:
  - `app.resetStopwatch()`, `WatchUi.popView(SLIDE_RIGHT)`, return `true`
- [ ] `onBack() as Boolean`:
  - `WatchUi.popView(SLIDE_RIGHT)`, return `true` (состояние секундомера НЕ сбрасывается)

Готовность: все три кнопки работают согласно ТЗ.

#### Задача 5: TimerDelegate — обработка кнопок на экране таймера
- **Файл:** `source/TimerDelegate.mc` (новый)
- **Агент:** `input-timer`
- **Зависимости:** Задача 4 (TimerView), Задача 1 (app методы)
- **Конфликты:** нет

Чек-лист:
- [ ] `class TimerDelegate extends WatchUi.BehaviorDelegate`
- [ ] Конструктор принимает `TimerView` (для доступа к setup-полям)
- [ ] **Setup mode** (когда `view.mSetupMode == true`):
  - [ ] UP — увеличить значение текущего поля
  - [ ] DOWN — уменьшить значение текущего поля
  - [ ] LIGHT/MENU — переключить поле (h→m→s→h)
  - [ ] SELECT — `app.startTimer(view.getSetupDurationMs())`, `view.mSetupMode = false`, requestUpdate
  - [ ] BACK — `popView(SLIDE_RIGHT)`
- [ ] **Active mode** (`view.mSetupMode == false`):
  - [ ] SELECT — `app.toggleTimerPause()`, requestUpdate
  - [ ] DOWN — `app.resetTimer()`, `popView(SLIDE_RIGHT)`
  - [ ] BACK — `popView(SLIDE_RIGHT)` (состояние сохраняется)

Готовность: все переходы и редактирование работают.

#### Задача 7: TactixDelegate — pushView вместо toggle, добавить DOWN
- **Файл:** `source/TactixDelegate.mc`
- **Агент:** `routing-main`
- **Зависимости:** Задачи 2 и 4 (классы StopwatchView и TimerView существуют)
- **Конфликты:** нет (другие в Волне 3 не трогают этот файл)

Чек-лист:
- [ ] Сохранить `mLastBackMs` (уже есть), добавить `mLastDownMs`
- [ ] `onBack()` изменить: при двойном нажатии вместо `toggleStopwatch()` →
  `WatchUi.pushView(new StopwatchView(), new StopwatchDelegate(), WatchUi.SLIDE_LEFT)`
- [ ] Добавить `onNextPage()` или `onKey()` для KEY_DOWN: двойное нажатие →
  `WatchUi.pushView(new TimerView(), new TimerDelegate(), WatchUi.SLIDE_LEFT)`
  (см. примечание ниже про TimerView и TimerDelegate: TimerDelegate берёт ссылку
  на view)
- [ ] Одиночные нажатия — поглощаются (return true), без действия

Примечание: создание `TimerDelegate(view)` требует передать view. Вариант:
```
var v = new TimerView();
WatchUi.pushView(v, new TimerDelegate(v), WatchUi.SLIDE_LEFT);
```

Готовность: двойное BACK → экран секундомера; двойное DOWN → экран таймера.

---

## 5. Финальная интеграция

- [ ] Все 7 задач отмечены как готовые
- [ ] Сборка `monkeyc -f monkey_clear.jungle -d fenix8solar47mm -o tactix_clear.prg`
  проходит без ошибок
- [ ] Запуск в симуляторе fenix8solar47mm
- [ ] Тест-кейсы (см. раздел 6) пройдены

---

## 6. Тест-кейсы для приёмки

### Главный экран
- [ ] При отсутствии секундомера и таймера показывается стандартный будильник
  под стрелками
- [ ] Одиночное BACK — ничего не происходит
- [ ] Одиночное DOWN — ничего не происходит

### Секундомер
- [ ] Двойное BACK на главном → открывается экран секундомера с 00:00:00:00
- [ ] START на экране секундомера запускает счёт; формат `ЧЧ:ММ:СС:сс` синим
- [ ] Видимое обновление ~25 fps (плавное изменение сотых)
- [ ] START повторно — пауза; цифры замирают
- [ ] START после паузы — продолжение с сохранённой позиции
- [ ] BACK на экране секундомера — возврат на главный; на главном виден
  overlay секундомера синим поверх стрелок, ЧЧ:ММ:СС, обновление раз в секунду
- [ ] Двойное BACK снова → возврат на экран секундомера с текущим значением
- [ ] DOWN на экране секундомера → сброс + возврат на главный; на главном
  больше нет overlay секундомера

### Таймер
- [ ] Двойное DOWN на главном (когда таймер не активен) → экран setup с 00:05:00
  красным
- [ ] UP — увеличивает текущее поле, DOWN — уменьшает
- [ ] LIGHT/MENU — переключает поле, курсор виден
- [ ] START в setup → запуск таймера, экран переключается в active mode
- [ ] Обратный отсчёт ЧЧ:ММ:СС красным, обновление раз в секунду
- [ ] START в active — пауза; повторно — продолжить
- [ ] BACK на active → возврат на главный; на главном виден overlay таймера
  красным поверх стрелок, ЧЧ:ММ:СС
- [ ] Двойное DOWN снова → возврат на active mode с текущим значением
- [ ] DOWN на active → сброс + возврат на главный
- [ ] Когда таймер дошёл до 00:00:00 — таймер останавливается (`tRunning = false`),
  на главном overlay таймера исчезает или показывает 00:00:00 (поведение
  уточнить в Задаче 1)

### Приоритет на главном экране
- [ ] Если активны и таймер, и секундомер — показывается таймер (красный)
- [ ] Если активен только секундомер — синий overlay
- [ ] Если активен только таймер — красный overlay
- [ ] Если ничего — будильник

### Утечки ресурсов
- [ ] При уходе с экрана секундомера — `Timer.Timer` останавливается (`onHide`)
- [ ] При уходе с экрана таймера — то же
- [ ] При уходе с экрана секундомера во время счёта — состояние сохранено в
  `TactixApp`, счёт продолжается логически

---

## 7. Открытые вопросы (обсудить перед началом)

1. **Поведение при достижении 00:00:00 в таймере** — звук/вибрация? Просто
   останавливается? Уточнить.
2. **Точность отображения сотых** — 25 fps означает шаг 40 мс, значит сотые
   будут "прыгать" по 4 единицы. ТЗ это допускает (раз в 40 мс).
3. **Установка времени таймера** — кнопка переключения поля. В плане LIGHT/MENU
   — допустимо?
4. **Когда таймер истёк (00:00:00) и таймер всё ещё `tRunning`** — нужно ли
   автоматически вызвать `resetTimer()` в `getTimerRemainingMs()`?

---

## 8. История изменений

- 2026-05-18 — план создан
