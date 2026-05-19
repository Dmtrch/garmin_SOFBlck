import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class StopwatchListDelegate extends WatchUi.BehaviorDelegate {

    private static const DOUBLE_MS as Number = 500;

    private var mLastStartMs  as Number       = 0;
    private var mPendingTimer as Timer.Timer? = null;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onPreviousPage() as Boolean {
        _cancelPending();
        var app = Application.getApp() as TactixApp;
        app.swSelectedIdx = (app.swSelectedIdx + 4) % 5;
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        _cancelPending();
        var app = Application.getApp() as TactixApp;
        app.swSelectedIdx = (app.swSelectedIdx + 1) % 5;
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var now = System.getTimer();
        if (now - mLastStartMs <= DOUBLE_MS) {
            // двойное нажатие — сброс
            mLastStartMs = 0;
            _cancelPending();
            var app = Application.getApp() as TactixApp;
            app.resetStopwatch(app.swSelectedIdx);
            WatchUi.requestUpdate();
        } else {
            // первое нажатие — ждём, не было ли двойного
            mLastStartMs = now;
            _cancelPending();
            mPendingTimer = new Timer.Timer();
            mPendingTimer.start(method(:onToggle), DOUBLE_MS + 50, false);
        }
        return true;
    }

    // вызывается таймером если второго нажатия не было → одиночный старт/стоп
    function onToggle() as Void {
        mPendingTimer = null;
        mLastStartMs  = 0;
        var app = Application.getApp() as TactixApp;
        app.toggleStopwatch(app.swSelectedIdx);
        WatchUi.requestUpdate();
    }

    function onBack() as Boolean {
        _cancelPending();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    private function _cancelPending() as Void {
        if (mPendingTimer != null) {
            mPendingTimer.stop();
            mPendingTimer = null;
        }
    }
}
