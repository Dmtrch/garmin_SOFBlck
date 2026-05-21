import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class TactixDelegate extends NoTouchDelegate {

    private static const DOUBLE_PRESS_MS as Number = 500;

    private var mLastBackMs   as Number       = 0;
    private var mLastUpMs     as Number       = 0;
    private var mLastDownMs   as Number       = 0;
    private var mLastStartMs  as Number       = 0;
    private var mBackTimer    as Timer.Timer? = null;

    function initialize() {
        NoTouchDelegate.initialize();
    }

    function onPreviousPage() as Boolean {
        var now = System.getTimer();
        if (now - mLastUpMs <= DOUBLE_PRESS_MS) {
            mLastUpMs = 0;
            var lv = new AlarmListView();
            WatchUi.pushView(lv, new AlarmListDelegate(lv), WatchUi.SLIDE_UP);
        } else {
            mLastUpMs = now;
        }
        return true;
    }

    function onBack() as Boolean {
        var now = System.getTimer();
        if (now - mLastBackMs <= DOUBLE_PRESS_MS) {
            mLastBackMs = 0;
            _cancelBackTimer();
            var app = Application.getApp() as TactixApp;
            app.toggleCompass();
            WatchUi.requestUpdate();
        } else {
            mLastBackMs = now;
            _cancelBackTimer();
            mBackTimer = new Timer.Timer();
            mBackTimer.start(method(:onSingleBack), DOUBLE_PRESS_MS + 50, false);
        }
        return true;
    }

    function onSingleBack() as Void {
        mBackTimer  = null;
        mLastBackMs = 0;
        var app = Application.getApp() as TactixApp;
        if (app.compassActive || app.compassError) {
            app.toggleCompass();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    private function _cancelBackTimer() as Void {
        if (mBackTimer != null) {
            mBackTimer.stop();
            mBackTimer = null;
        }
    }

    function onNextPage() as Boolean {
        var now = System.getTimer();
        if (now - mLastDownMs <= DOUBLE_PRESS_MS) {
            mLastDownMs = 0;
            var view = new TimerView();
            WatchUi.pushView(view, new TimerDelegate(view), WatchUi.SLIDE_LEFT);
        } else {
            mLastDownMs = now;
        }
        return true;
    }

    function onSelect() as Boolean {
        var now = System.getTimer();
        if (now - mLastStartMs <= DOUBLE_PRESS_MS) {
            mLastStartMs = 0;
            WatchUi.pushView(new StopwatchListView(), new StopwatchListDelegate(),
                             WatchUi.SLIDE_LEFT);
        } else {
            mLastStartMs = now;
        }
        return true;
    }
}
