import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class TactixApp extends Application.AppBase {

    // --- Stopwatch state (5 independent stopwatches) ---
    var swRunning     as Array = [false, false, false, false, false] as Array;
    var swStartMs     as Array = [0, 0, 0, 0, 0] as Array;
    var swOffsetMs    as Array = [0, 0, 0, 0, 0] as Array;
    var swSelectedIdx as Number = 0;

    // --- Timers (5 independent countdown timers) ---
    var tmRunning     as Array  = [false, false, false, false, false] as Array;
    var tmStartMs     as Array  = [0, 0, 0, 0, 0] as Array;
    var tmRemainMs    as Array  = [0, 0, 0, 0, 0] as Array;
    var tmExpired     as Array  = [false, false, false, false, false] as Array;
    var tmNotified    as Array  = [false, false, false, false, false] as Array;
    var tmDurationMs  as Array  = [0, 0, 0, 0, 0] as Array;
    var tmSelectedIdx as Number = 0;

    // --- Alarm state ---
    private var mAlarms       as Array?  = null;
    private var mLastFiredMin as Number  = -1;

    // --- Alarm notification state ---
    private var mAlarmNotifTimer as Timer.Timer? = null;
    private var mAlarmToneCount  as Number       = 0;
    private var mAlarmVibe       as Boolean      = false;
    private var mAlarmSound      as Boolean      = false;

    // --- Timer notification state ---
    private var mTimerNotifTimer  as Timer.Timer? = null;
    private var mTimerToneCount   as Number       = 0;

    // --- Compass state ---
    var compassActive    as Boolean = false; // sensor on, drawing arrows
    var compassError     as Boolean = false; // heading unavailable, show msg
    var compassHeading   as Float?  = null;  // radians, 0 = N, CW
    var compassHeadingMs as Number  = 0;     // System.getTimer() at last fresh heading
    private var mCompassErrTimer as Timer.Timer?;
    private var mSensorWarmupMs  as Number = 0; // System.getTimer() at last _ensureMagnetometer

    // --- Bearing state (multi-target) ---
    var bearingActive          as Boolean        = false;
    var bearingTargetIndices   as Array<Number>  = [] as Array<Number>;
    var bearingDistancesM      as Array<Float>   = [] as Array<Float>;
    var bearingDirectionsRad   as Array<Float>   = [] as Array<Float>;
    var bearingLastLat         as Double         = 0.0d;
    var bearingLastLon         as Double         = 0.0d;
    var bearingGpsFix          as Boolean        = false;
    var gpsActive              as Boolean        = false;
    var gpsQuality             as Number         = Position.QUALITY_NOT_AVAILABLE;
    var hasPositionFix         as Boolean        = false;

    // --- Accent mode state ---
    var accentIndex   as Number  = -1;    // -1 = режим выключен, иначе 0..11
    var accentValueStr as String? = null; // кэш отображаемого значения акцента
    var accentValueTs  as Number  = 0;    // System.getTimer() последней фиксации
    // Период перечитывания значения (мс) по индексу показателя (см. план)
    var accentPeriods as Array<Number> =
        [300000,1000,5000,300000,300000,300000,300000,300000,5000,30000,5000,300000] as Array<Number>;
    // Live-значения датчиков (только пока выбран соответствующий idx)
    var currentHr       as Number? = null;
    var currentAltitude as Float?  = null;
    var currentPressure as Float?  = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        _restoreStopwatch();
        _restoreTimer();
    }

    function onStop(state as Dictionary?) as Void {
        _saveStopwatch();
        _saveTimer();
        _resetAccentState();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
        Sensor.enableSensorEvents(null);
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new EcoView();
        return [view, new EcoDelegate(view)];
    }

    // ====== Persistence ======

    private function _saveStopwatch() as Void {
        var saveData = new [5] as Array;
        for (var i = 0; i < 5; i++) {
            var running = swRunning[i] as Boolean;
            var elapsed = running
                ? (swOffsetMs[i] as Number) + (System.getTimer() - (swStartMs[i] as Number))
                : swOffsetMs[i] as Number;
            saveData[i] = {
                "offset"  => elapsed,
                "running" => running,
                "save_t"  => running ? Time.now().value() : 0l
            } as Dictionary;
        }
        Application.Storage.setValue("sw5_data", saveData);
    }

    private function _restoreStopwatch() as Void {
        var raw = Application.Storage.getValue("sw5_data");
        if (!(raw instanceof Array)) { return; }
        var arr = raw as Array;
        var n = arr.size() < 5 ? arr.size() : 5;
        for (var i = 0; i < n; i++) {
            var entry = arr[i];
            if (!(entry instanceof Dictionary)) { continue; }
            var d = entry as Dictionary;
            var offset = d["offset"];
            if (!(offset instanceof Number)) { continue; }
            swOffsetMs[i] = offset as Number;
            var wasRunning = d["running"];
            if (wasRunning instanceof Boolean && wasRunning as Boolean) {
                var saveT = d["save_t"];
                if (saveT != null) {
                    var delta = ((Time.now().value() - (saveT as Long)) * 1000l).toNumber();
                    swOffsetMs[i] = (swOffsetMs[i] as Number) + delta;
                }
                swStartMs[i] = System.getTimer();
                swRunning[i] = true;
            }
        }
    }

    private function _saveTimer() as Void {
        var saveData = new [5] as Array;
        for (var i = 0; i < 5; i++) {
            var running = tmRunning[i] as Boolean;
            var remain = running
                ? (tmRemainMs[i] as Number) - (System.getTimer() - (tmStartMs[i] as Number))
                : tmRemainMs[i] as Number;
            if (remain < 0) { remain = 0; }
            saveData[i] = {
                "remain"   => remain,
                "duration" => tmDurationMs[i] as Number,
                "running"  => running,
                "expired"  => tmExpired[i] as Boolean,
                "save_t"   => running ? Time.now().value() : 0l
            } as Dictionary;
        }
        Application.Storage.setValue("tm5_data", saveData);
    }

    private function _restoreTimer() as Void {
        var raw = Application.Storage.getValue("tm5_data");
        if (!(raw instanceof Array)) { return; }
        var arr = raw as Array;
        var n = arr.size() < 5 ? arr.size() : 5;
        for (var i = 0; i < n; i++) {
            var entry = arr[i];
            if (!(entry instanceof Dictionary)) { continue; }
            var d = entry as Dictionary;
            var dur = d["duration"];
            if (dur instanceof Number) { tmDurationMs[i] = dur as Number; }
            var wasExpired = d["expired"];
            if (wasExpired instanceof Boolean) { tmExpired[i] = wasExpired as Boolean; }
            var remain = d["remain"];
            if (!(remain instanceof Number)) { continue; }
            var wasRunning = d["running"];
            if (wasRunning instanceof Boolean && wasRunning as Boolean) {
                var saveT = d["save_t"];
                var elapsedMs = 0;
                if (saveT != null) {
                    elapsedMs = ((Time.now().value() - (saveT as Long)) * 1000l).toNumber();
                }
                var newRemain = (remain as Number) - elapsedMs;
                if (newRemain <= 0) {
                    tmRemainMs[i] = 0;
                    tmExpired[i]  = true;
                } else {
                    tmRemainMs[i] = newRemain;
                    tmStartMs[i]  = System.getTimer();
                    tmRunning[i]  = true;
                }
            } else {
                tmRemainMs[i] = remain as Number;
            }
        }
    }

    // ====== Alarms ======

    function getAlarms() as Array {
        if (mAlarms == null) {
            mAlarms = AlarmManager.load();
        }
        return mAlarms as Array;
    }

    function reloadAlarms() as Void {
        mAlarms = AlarmManager.load();
        WatchUi.requestUpdate();
    }

    function checkAlarms() as Void {
        var fired = AlarmManager.checkFire(getAlarms(), mLastFiredMin);
        if (fired != null) {
            var clock = System.getClockTime();
            mLastFiredMin = clock.hour * 60 + clock.min;
            _fireAlarm(fired as Dictionary);
        }
    }

    private function _fireAlarm(alarm as Dictionary) as Void {
        mAlarmVibe      = alarm["vibe"]  as Boolean;
        mAlarmSound     = alarm["sound"] as Boolean;
        mAlarmToneCount = 0;

        _alarmPulse(); // первый импульс сразу

        if (mAlarmNotifTimer == null) { mAlarmNotifTimer = new Timer.Timer(); }
        mAlarmNotifTimer.start(method(:onAlarmTick), 1000, true);

        WatchUi.pushView(
            new AlarmNotificationView(alarm["hour"] as Number, alarm["min"] as Number),
            new AlarmNotificationDelegate(),
            WatchUi.SLIDE_UP);
    }

    function onAlarmTick() as Void {
        mAlarmToneCount++;
        _alarmPulse();
    }

    // Вибро каждый тик (10 раз), звук на чётных тиках (5 раз: 0,2,4,6,8)
    private function _alarmPulse() as Void {
        if (mAlarmVibe && (Attention has :vibrate)) {
            var p = [new Attention.VibeProfile(100, 600)] as Array<Attention.VibeProfile>;
            Attention.vibrate(p);
        }
        if (mAlarmSound && (mAlarmToneCount % 2 == 0) && (Attention has :playTone)) {
            Attention.playTone(Attention.TONE_ALARM);
        }
    }

    function stopAlarmNotification() as Void {
        _stopAlarmNotifTimer();
    }

    private function _stopAlarmNotifTimer() as Void {
        if (mAlarmNotifTimer != null) {
            mAlarmNotifTimer.stop();
            mAlarmNotifTimer = null;
        }
    }

    // ====== Stopwatch ======

    function toggleStopwatch(idx as Number) as Void {
        if (swRunning[idx] as Boolean) {
            swOffsetMs[idx] = (swOffsetMs[idx] as Number) + (System.getTimer() - (swStartMs[idx] as Number));
            swRunning[idx] = false;
        } else {
            swStartMs[idx] = System.getTimer();
            swRunning[idx] = true;
        }
    }

    function resetStopwatch(idx as Number) as Void {
        swRunning[idx]  = false;
        swStartMs[idx]  = 0;
        swOffsetMs[idx] = 0;
    }

    function getSwElapsedMs(idx as Number) as Number {
        if (swRunning[idx] as Boolean) {
            return (swOffsetMs[idx] as Number) + (System.getTimer() - (swStartMs[idx] as Number));
        }
        return swOffsetMs[idx] as Number;
    }

    function hasStopwatch() as Boolean {
        var idx = swSelectedIdx;
        return (swRunning[idx] as Boolean) || (swOffsetMs[idx] as Number) > 0;
    }

    // ====== Timer (countdown) ======

    function startTimerAt(idx as Number, durationMs as Number) as Void {
        tmDurationMs[idx] = durationMs;
        tmRemainMs[idx]   = durationMs;
        tmStartMs[idx]    = System.getTimer();
        tmRunning[idx]    = true;
        tmExpired[idx]    = false;
    }

    function toggleTimerPauseAt(idx as Number) as Void {
        if (tmExpired[idx] as Boolean) { return; }
        if (tmRunning[idx] as Boolean) {
            var elapsed = System.getTimer() - (tmStartMs[idx] as Number);
            var remain = (tmRemainMs[idx] as Number) - elapsed;
            tmRemainMs[idx] = remain < 0 ? 0 : remain;
            tmRunning[idx]  = false;
        } else if ((tmRemainMs[idx] as Number) > 0) {
            tmStartMs[idx] = System.getTimer();
            tmRunning[idx] = true;
        }
    }

    function resetTimerAt(idx as Number) as Void {
        tmRunning[idx]   = false;
        tmStartMs[idx]   = 0;
        tmRemainMs[idx]  = 0;
        tmExpired[idx]   = false;
        tmNotified[idx]  = false;
    }

    function getTimerRemainingMsAt(idx as Number) as Number {
        if (tmRunning[idx] as Boolean) {
            var remain = (tmRemainMs[idx] as Number) - (System.getTimer() - (tmStartMs[idx] as Number));
            if (remain <= 0) {
                tmRunning[idx]  = false;
                tmRemainMs[idx] = 0;
                tmExpired[idx]  = true;
                return 0;
            }
            return remain;
        }
        return tmRemainMs[idx] as Number;
    }

    function hasTimerAt(idx as Number) as Boolean {
        return (tmRunning[idx] as Boolean) || (tmRemainMs[idx] as Number) > 0 || (tmExpired[idx] as Boolean);
    }

    function checkTimers() as Void {
        for (var i = 0; i < 5; i++) {
            if (tmRunning[i] as Boolean) {
                getTimerRemainingMsAt(i); // обновляет expired если истёк
            }
            if ((tmExpired[i] as Boolean) && !(tmNotified[i] as Boolean)) {
                tmNotified[i] = true;
                _fireTimerExpired(i);
                break;
            }
        }
    }

    private function _fireTimerExpired(idx as Number) as Void {
        mTimerToneCount = 0;
        _timerAlertPulse();
        if (mTimerNotifTimer == null) { mTimerNotifTimer = new Timer.Timer(); }
        mTimerNotifTimer.start(method(:onTimerNotifTick), 1000, true);
        WatchUi.pushView(
            new TimerNotificationView(idx + 1),
            new TimerNotificationDelegate(idx),
            WatchUi.SLIDE_UP);
    }

    function onTimerNotifTick() as Void {
        mTimerToneCount++;
        _timerAlertPulse();
    }

    function stopTimerNotification() as Void {
        if (mTimerNotifTimer != null) {
            mTimerNotifTimer.stop();
            mTimerNotifTimer = null;
        }
        mTimerToneCount = 0;
    }

    function getNearestTimerRemainingMs() as Number {
        var best = -1;
        for (var i = 0; i < 5; i++) {
            if (tmRunning[i] as Boolean) {
                var r = getTimerRemainingMsAt(i);
                if (r > 0 && (best < 0 || r < best)) { best = r; }
            }
        }
        return best;
    }

    function getNearestAlarmTime() as Array? {
        var alarms  = getAlarms();
        var clock   = System.getClockTime();
        var nowMins = clock.hour * 60 + clock.min;
        var best    = -1;
        var bestH   = 0;
        var bestM   = 0;
        for (var i = 0; i < alarms.size(); i++) {
            var a = alarms[i] as Dictionary;
            if (!(a["enabled"] as Boolean)) { continue; }
            var h    = a["hour"] as Number;
            var m    = a["min"]  as Number;
            var diff = h * 60 + m - nowMins;
            if (diff < 0) { diff += 24 * 60; }
            if (best < 0 || diff < best) { best = diff; bestH = h; bestM = m; }
        }
        if (best < 0) { return null; }
        return [bestH, bestM] as Array<Number>;
    }

    function hasTimer() as Boolean {
        for (var i = 0; i < 5; i++) {
            if (hasTimerAt(i)) { return true; }
        }
        return false;
    }

    function getTimerRemainingMs() as Number {
        return getTimerRemainingMsAt(tmSelectedIdx);
    }

    // ====== Accent mode ======

    function accentNext() as Void {
        accentIndex = (accentIndex < 0) ? 0 : (accentIndex + 1) % 12;
        _clearAccentCache();
        _syncSensors();
        WatchUi.requestUpdate();
    }

    function accentPrev() as Void {
        accentIndex = (accentIndex < 0) ? 11 : (accentIndex + 11) % 12;
        _clearAccentCache();
        _syncSensors();
        WatchUi.requestUpdate();
    }

    function accentOff() as Void {
        _resetAccentState();
        _syncSensors();
        WatchUi.requestUpdate();
    }

    // Сброс частотного кэша и live-значений при смене показателя.
    private function _clearAccentCache() as Void {
        accentValueStr  = null;
        accentValueTs   = 0;
        currentHr       = null;
        currentAltitude = null;
        currentPressure = null;
    }

    // Полный выход из режима акцента.
    private function _resetAccentState() as Void {
        accentIndex = -1;
        _clearAccentCache();
    }

    // ====== Compass ======

    function toggleCompass() as Void {
        if (compassActive || compassError) {
            compassActive = false;
            compassError  = false;
            _syncSensors();
            return;
        }
        compassActive  = true;
        compassError   = false;
        _syncSensors();
    }

    // Единый колбэк сенсоров (heading для компаса/пеленга + live HR/высота/давление
    // для режима акцента). Один enableSensorEvents на приложение → один диспетчер.
    function onSensor(info as Sensor.Info) as Void {
        // --- Heading (компас / пеленг) ---
        if (compassActive || bearingActive) {
            if (info.heading != null) {
                compassHeading   = info.heading;
                compassHeadingMs = System.getTimer();
                compassError     = false;
            } else if (System.getTimer() - mSensorWarmupMs >= 2000) {
                // Прогрев магнитометра ~2 с — до этого null heading нормально.
                if (compassActive) {
                    compassActive = false;
                    compassError  = true;
                    if (mCompassErrTimer == null) { mCompassErrTimer = new Timer.Timer(); }
                    mCompassErrTimer.start(method(:onCompassErrorClear), 2000, false);
                }
                compassHeading = null;
                // Подписка больше не нужна для heading — пересобираем набор
                // (останется включённой, если её держит акцент-датчик).
                _syncSensors();
            }
        }
        // --- Live-датчики режима акцента ---
        if (accentIndex == 1 && info.heartRate != null) {
            currentHr = info.heartRate;
        }
        if (accentIndex == 2 && info.altitude != null) {
            currentAltitude = info.altitude;
        }
        if (accentIndex == 8 && info.pressure != null) {
            currentPressure = info.pressure;
        }
        WatchUi.requestUpdate();
    }

    function onCompassErrorClear() as Void {
        compassError = false;
        if (mCompassErrTimer != null) {
            mCompassErrTimer.stop();
            mCompassErrTimer = null;
        }
        WatchUi.requestUpdate();
    }

    // ====== Bearing ======

    function startBearing(indices as Array<Number>) as Void {
        if (indices.size() == 0) { return; }
        bearingTargetIndices = indices;
        bearingActive = true;
        bearingGpsFix = false;
        bearingDistancesM = new [indices.size()] as Array<Float>;
        bearingDirectionsRad = new [indices.size()] as Array<Float>;
        for (var i = 0; i < indices.size(); i++) {
            bearingDistancesM[i] = -1.0f;
            bearingDirectionsRad[i] = 0.0f;
        }
        // Синхронно заполняем дистанции/направления из текущего фикса —
        // чтобы числа появились сразу, не дожидаясь callback'а LOCATION_CONTINUOUS.
        _seedBearingFromCurrentFix();
        // Магнитометр должен работать всегда, когда активен пеленг —
        // без heading стрелка не вращается при повороте часов.
        _syncSensors();
        WatchUi.requestUpdate();
    }

    private function _seedBearingFromCurrentFix() as Void {
        var posInfo = Position.getInfo();
        if (posInfo == null || posInfo.position == null
            || posInfo.accuracy == null
            || posInfo.accuracy < Position.QUALITY_POOR) { return; }
        var coords = (posInfo.position as Position.Location).toDegrees();
        bearingLastLat = coords[0] as Double;
        bearingLastLon = coords[1] as Double;
        bearingGpsFix = true;
        var wps = NavManager.load();
        for (var i = 0; i < bearingTargetIndices.size(); i++) {
            var idx = bearingTargetIndices[i] as Number;
            if (idx < 0 || idx >= wps.size()) { continue; }
            var wp = wps[idx] as Dictionary;
            bearingDistancesM[i] = NavManager.distanceM(
                bearingLastLat, bearingLastLon,
                wp["lat"] as Double, wp["lon"] as Double);
            bearingDirectionsRad[i] = NavManager.bearingRad(
                bearingLastLat, bearingLastLon,
                wp["lat"] as Double, wp["lon"] as Double);
        }
    }

    function stopBearing() as Void {
        bearingActive = false;
        bearingGpsFix = false;
        bearingTargetIndices = [] as Array<Number>;
        bearingDistancesM = [] as Array<Float>;
        bearingDirectionsRad = [] as Array<Float>;
        // Если компас не показан пользователем — магнитометр гасим.
        _syncSensors();
        WatchUi.requestUpdate();
    }

    function onPositionUpdate(info as Position.Info) as Void {
        if (info.position == null
            || info.accuracy == null
            || info.accuracy < Position.QUALITY_POOR) {
            // accuracy может быть GOOD, но position == null — реального фикса нет.
            gpsQuality = Position.QUALITY_NOT_AVAILABLE;
            hasPositionFix = false;
            if (bearingActive) {
                bearingGpsFix = false;
            }
            WatchUi.requestUpdate();
            return;
        }
        gpsQuality = info.accuracy;
        hasPositionFix = true;
        if (bearingActive) {
            var coords = info.position.toDegrees();
            bearingLastLat = coords[0] as Double;
            bearingLastLon = coords[1] as Double;
            bearingGpsFix = true;
            var wps = NavManager.load();
            for (var i = 0; i < bearingTargetIndices.size(); i++) {
                var idx = bearingTargetIndices[i] as Number;
                if (idx < 0 || idx >= wps.size()) { continue; }
                var wp = wps[idx] as Dictionary;
                bearingDistancesM[i] = NavManager.distanceM(
                    bearingLastLat, bearingLastLon,
                    wp["lat"] as Double, wp["lon"] as Double);
                bearingDirectionsRad[i] = NavManager.bearingRad(
                    bearingLastLat, bearingLastLon,
                    wp["lat"] as Double, wp["lon"] as Double);
            }
        }
        WatchUi.requestUpdate();
    }

    // Заглушить сенсоры при уходе на эко-экран (флаги компаса/пеленга сохраняются,
    // режим акцента сбрасывается полностью).
    function suspendSensors() as Void {
        _resetAccentState();
        Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
        if (compassActive || bearingActive) {
            Sensor.enableSensorEvents(null);
            compassHeading   = null;
            compassHeadingMs = 0;
        }
    }

    // Восстановить сенсоры при возврате на главный экран.
    function resumeSensors() as Void {
        _syncSensors();
    }

    // Единый диспетчер подписки на сенсоры. Пересобирает набор по текущему
    // состоянию (компас/пеленг + выбранный показатель акцента).
    // heading/altitude/pressure — positional/onboard, приходят в Info без явного
    // включения; heartRate включается точечно через enable/disableSensorType,
    // чтобы не перезаписать набор и не сбить heading.
    private function _syncSensors() as Void {
        var needHeading = compassActive || bearingActive;
        var needHr      = (accentIndex == 1);
        var needAny     = needHeading || needHr
                          || (accentIndex == 2) || (accentIndex == 8);

        if (needHr) {
            Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
        } else {
            Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
        }

        if (needAny) {
            mSensorWarmupMs = System.getTimer();
            Sensor.enableSensorEvents(method(:onSensor));
        } else {
            Sensor.enableSensorEvents(null);
            compassHeading   = null;
            compassHeadingMs = 0;
            if (mCompassErrTimer != null) {
                mCompassErrTimer.stop();
                mCompassErrTimer = null;
            }
        }
    }

    private function _timerAlertPulse() as Void {
        if (Attention has :vibrate) {
            var p = [new Attention.VibeProfile(100, 600)] as Array<Attention.VibeProfile>;
            Attention.vibrate(p);
        }
        if (mTimerToneCount % 2 == 0 && (Attention has :playTone)) {
            Attention.playTone(Attention.TONE_ALARM);
        }
    }

    private function _vibrateOnExpire() as Void {
        if (Attention has :vibrate) {
            var pattern = [
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0,   200),
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0,   200),
                new Attention.VibeProfile(100, 400)
            ] as Array<Attention.VibeProfile>;
            Attention.vibrate(pattern);
        }
    }

    // ====== GPS (Start кнопка) ======

    function toggleGps() as Void {
        if (gpsActive) {
            gpsActive = false;
            gpsQuality = Position.QUALITY_NOT_AVAILABLE;
            hasPositionFix = false;
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
            // Пеленг продолжает рисоваться, но без GPS-обновлений данные устаревают —
            // показываем "GPS..." вместо стрелок, чтобы не вводить пользователя в заблуждение.
            if (bearingActive) {
                bearingGpsFix = false;
            }
        } else {
            gpsActive = true;
            Position.enableLocationEvents(
                { :acquisitionType => Position.LOCATION_CONTINUOUS },
                method(:onPositionUpdate));
        }
    }
}
