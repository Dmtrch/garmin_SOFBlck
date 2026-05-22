# Tactix watchface project

## Соглашения сборки

- **Имена бинарников**: префикс `SOFBlck_` (НЕ `tactix_`).
  Формат: `SOFBlck_<device>.prg`
  Примеры: `SOFBlck_fenix8solar47mm.prg`, `SOFBlck_fenix8solar51mm.prg`

- **Signing key**: `/Users/dim/garmin/clock/pilot/developer_key.der`
  (НЕ `~/.Garmin/tactix.der` — другой ключ, симулятор крашится с ним).

- **Jungle**: `monkey_clear.jungle` → `manifest_clear.xml`

- **SDK**: ConnectIQ SDK 9.1.0+ (требуется API Level 6.0.0 для fenix8solar*).
  Путь: `~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-*/bin/monkeyc`

## Команда сборки

```bash
monkeyc -f monkey_clear.jungle \
  -o bin/SOFBlck_<device>.prg \
  -d <device> \
  -y /Users/dim/garmin/clock/pilot/developer_key.der
```

## Устройства и ресурсы

| Device            | Resolution | Background source         |
|-------------------|------------|---------------------------|
| fenix8solar47mm   | 260x260    | img/bc_260_clear.png      |
| fenix8solar51mm   | 280x280    | img/bc_280_clear.png      |
| fenix847mm        | 454x454    | img/bc454_final.png       |
| epix2pro47mm      | 416x416    | img/bc416_final.png       |
| epix2pro42mm      | 390x390    | img/bc390_final.png       |
| fr265s            | 360x360    | img/bc360_final.png       |

## Деплой в симулятор

```bash
monkeydo bin/SOFBlck_<device>.prg <device>
```

## Навигационные модули (source/)

| Файл | Назначение |
|------|-----------|
| `NavManager.mc` | Хранение меток в `Application.Storage` ("nav_wp"), гаверсинус-дистанция, пеленг |
| `NavMenuDelegate.mc` | Корневое меню навигации (двойной BACK); `pushNavMenu()` |
| `WaypointMenuDelegate.mc` | Подменю «Установить метку»: GPS / вручную / карта / удалить |
| `WaypointListDelegate.mc` | Список меток: режимы `:pickForDelete` и `:pickForBearing` |
| `WaypointEditView.mc` | Ручной ввод координат (6 полей: знак/°/дробь для lat и lon) |
| `MapPickView.mc` | Карта `WatchUi.MapView`: офлайн-карты OSM с диска часов; курсор-крест в центре; pan; bbox ±500 м |
| `MapPickDelegate.mc` | `BehaviorDelegate` (touch вкл): `onDrag` → pan; UP/DOWN → шаг 50 м по оси; START → переключение оси; SELECT → сохранить |

Пермишн `Positioning` объявлен в `manifest_clear.xml`. `Communications` удалён — `WatchUi.MapView` использует офлайн-карты и сетевого доступа не требует.  
Состояние пеленга хранится в `TactixApp` (`bearingActive`, `bearingDirectionRad`, …); отрисовка — `TactixView.drawBearing()`.

Подробный план реализации MapPick — в `Map_navi.md`.
