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
