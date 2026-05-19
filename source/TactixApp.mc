import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class TactixApp extends Application.AppBase {

    // --- Stopwatch state ---
    var swRunning  as Boolean = false;
    var swStartMs  as Number  = 0;     // System.getTimer() at last start
    var swOffsetMs as Number  = 0;     // accumulated ms before current run

    // --- Timer (countdown) state ---
    var tRunning  as Boolean = false;
    var tStartMs  as Number  = 0;      // System.getTimer() at last start
    var tRemainMs as Number  = 0;      // remaining ms at last pause / start
    var tExpired  as Boolean = false;  // timer reached 0; awaits user reset

    // --- Alarm state ---
    private var mAlarms       as Array?  = null;
    private var mLastFiredMin as Number  = -1;

    // --- Alarm notification state ---
    private var mAlarmNotifTimer as Timer.Timer? = null;
    private var mAlarmToneCount  as Number       = 0;
    private var mAlarmVibe       as Boolean      = false;
    private var mAlarmSound      as Boolean      = false;

    // --- Compass state ---
    var compassActive  as Boolean = false;   // sensor on, drawing arrows
    var compassError   as Boolean = false;   // heading unavailable, show msg
    var compassHeading as Float?  = null;    // radians, 0 = N, CW
    private var mCompassErrTimer as Timer.Timer?;

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
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new TactixView(), new TactixDelegate()];
    }

    // ====== Persistence ======

    private function _saveStopwatch() as Void {
        var elapsed = swRunning
            ? swOffsetMs + (System.getTimer() - swStartMs)
            : swOffsetMs;
        Application.Storage.setValue("sw_offset",  elapsed);
        Application.Storage.setValue("sw_running", swRunning);
        if (swRunning) {
            Application.Storage.setValue("sw_save_t", Time.now().value());
        }
    }

    private function _restoreStopwatch() as Void {
        var offset = Application.Storage.getValue("sw_offset");
        if (!(offset instanceof Number)) { return; }
        swOffsetMs = offset as Number;
        var wasRunning = Application.Storage.getValue("sw_running");
        if (wasRunning instanceof Boolean && wasRunning as Boolean) {
            var saveT = Application.Storage.getValue("sw_save_t");
            if (saveT != null) {
                var elapsedMs = ((Time.now().value() - (saveT as Long)) * 1000l).toNumber();
                swOffsetMs = swOffsetMs + elapsedMs;
            }
            swStartMs = System.getTimer();
            swRunning = true;
        }
    }

    private function _saveTimer() as Void {
        var remain = tRunning
            ? tRemainMs - (System.getTimer() - tStartMs)
            : tRemainMs;
        if (remain < 0) { remain = 0; }
        Application.Storage.setValue("t_remain",  remain);
        Application.Storage.setValue("t_running", tRunning);
        Application.Storage.setValue("t_expired", tExpired);
        if (tRunning) {
            Application.Storage.setValue("t_save_t", Time.now().value());
        }
    }

    private function _restoreTimer() as Void {
        var remain = Application.Storage.getValue("t_remain");
        if (!(remain instanceof Number)) { return; }
        tExpired = false;
        var wasRunning = Application.Storage.getValue("t_running");
        var wasExpired = Application.Storage.getValue("t_expired");
        if (wasExpired instanceof Boolean) { tExpired = wasExpired as Boolean; }
        if (wasRunning instanceof Boolean && wasRunning as Boolean) {
            var saveT = Application.Storage.getValue("t_save_t");
            var elapsedMs = 0;
            if (saveT != null) {
                elapsedMs = ((Time.now().value() - (saveT as Long)) * 1000l).toNumber();
            }
            var newRemain = (remain as Number) - elapsedMs;
            if (newRemain <= 0) {
                tRemainMs = 0;
                tRunning  = false;
                tExpired  = true;
                _vibrateOnExpire();
            } else {
                tRemainMs = newRemain;
                tStartMs  = System.getTimer();
                tRunning  = true;
            }
        } else {
            tRemainMs = remain as Number;
            tRunning  = false;
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

    // Таймер: 1 раз в секунду, 9 дополнительных = 10 импульсов итого
    function onAlarmTick() as Void {
        mAlarmToneCount++;
        _alarmPulse();
        if (mAlarmToneCount >= 9) {
            _stopAlarmNotifTimer();
        }
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

    function toggleStopwatch() as Void {
        if (swRunning) {
            swOffsetMs += System.getTimer() - swStartMs;
            swRunning = false;
        } else {
            swStartMs = System.getTimer();
            swRunning = true;
        }
    }

    function resetStopwatch() as Void {
        swRunning  = false;
        swStartMs  = 0;
        swOffsetMs = 0;
    }

    function getSwElapsedMs() as Number {
        if (swRunning) {
            return swOffsetMs + (System.getTimer() - swStartMs);
        }
        return swOffsetMs;
    }

    function hasStopwatch() as Boolean {
        return swRunning || swOffsetMs > 0;
    }

    // ====== Timer (countdown) ======

    function startTimer(durationMs as Number) as Void {
        tRemainMs = durationMs;
        tStartMs  = System.getTimer();
        tRunning  = true;
        tExpired  = false;
    }

    function toggleTimerPause() as Void {
        if (tExpired) { return; }
        if (tRunning) {
            var elapsed = System.getTimer() - tStartMs;
            tRemainMs = tRemainMs - elapsed;
            if (tRemainMs < 0) { tRemainMs = 0; }
            tRunning = false;
        } else if (tRemainMs > 0) {
            tStartMs = System.getTimer();
            tRunning = true;
        }
    }

    function resetTimer() as Void {
        tRunning  = false;
        tStartMs  = 0;
        tRemainMs = 0;
        tExpired  = false;
    }

    function getTimerRemainingMs() as Number {
        if (tRunning) {
            var remain = tRemainMs - (System.getTimer() - tStartMs);
            if (remain <= 0) {
                tRunning  = false;
                tRemainMs = 0;
                tExpired  = true;
                _vibrateOnExpire();
                return 0;
            }
            return remain;
        }
        return tRemainMs;
    }

    function hasTimer() as Boolean {
        return tRunning || tRemainMs > 0 || tExpired;
    }

    // ====== Compass ======

    function toggleCompass() as Void {
        if (compassActive || compassError) {
            _compassOff();
            return;
        }
        compassActive  = true;
        compassError   = false;
        compassHeading = null;
        Sensor.enableSensorEvents(method(:onCompassSensor));
    }

    function onCompassSensor(info as Sensor.Info) as Void {
        if (!compassActive) { return; }
        if (info.heading != null) {
            compassHeading = info.heading;
            compassError   = false;
        } else {
            compassActive  = false;
            compassError   = true;
            compassHeading = null;
            Sensor.enableSensorEvents(null);
            if (mCompassErrTimer == null) { mCompassErrTimer = new Timer.Timer(); }
            mCompassErrTimer.start(method(:onCompassErrorClear), 2000, false);
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

    private function _compassOff() as Void {
        if (compassActive) {
            Sensor.enableSensorEvents(null);
        }
        compassActive  = false;
        compassError   = false;
        compassHeading = null;
        if (mCompassErrTimer != null) {
            mCompassErrTimer.stop();
            mCompassErrTimer = null;
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
}
