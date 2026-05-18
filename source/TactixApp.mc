import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
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

    // --- Compass state ---
    var compassActive  as Boolean = false;   // sensor on, drawing arrows
    var compassError   as Boolean = false;   // heading unavailable, show msg
    var compassHeading as Float?  = null;    // radians, 0 = N, CW
    private var mCompassErrTimer as Timer.Timer?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new TactixView(), new TactixDelegate()];
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
