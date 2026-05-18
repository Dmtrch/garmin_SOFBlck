import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class TactixDelegate extends WatchUi.BehaviorDelegate {

    private static const DOUBLE_PRESS_MS as Number = 500;

    private var mLastBackMs  as Number = 0;
    private var mLastDownMs  as Number = 0;
    private var mLastStartMs as Number = 0;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        var now = System.getTimer();
        if (now - mLastBackMs <= DOUBLE_PRESS_MS) {
            mLastBackMs = 0;
            WatchUi.pushView(new StopwatchView(), new StopwatchDelegate(),
                             WatchUi.SLIDE_LEFT);
        } else {
            mLastBackMs = now;
        }
        return true;
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
            var app = Application.getApp() as TactixApp;
            app.toggleCompass();
            WatchUi.requestUpdate();
        } else {
            mLastStartMs = now;
        }
        return true;
    }
}
