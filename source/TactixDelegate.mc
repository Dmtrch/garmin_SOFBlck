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
    private var mStartTimer   as Timer.Timer? = null;
    private var mUpTimer      as Timer.Timer? = null;
    private var mDownTimer    as Timer.Timer? = null;

    function initialize() {
        NoTouchDelegate.initialize();
    }

    function onPreviousPage() as Boolean {
        var now = System.getTimer();
        if (now - mLastUpMs <= DOUBLE_PRESS_MS) {
            mLastUpMs = 0;
            _cancelUpTimer();
            var lv = new AlarmListView();
            WatchUi.pushView(lv, new AlarmListDelegate(lv), WatchUi.SLIDE_UP);
        } else {
            mLastUpMs = now;
            _cancelUpTimer();
            mUpTimer = new Timer.Timer();
            mUpTimer.start(method(:onSingleUp), DOUBLE_PRESS_MS + 50, false);
        }
        return true;
    }

    function onSingleUp() as Void {
        mUpTimer  = null;
        mLastUpMs = 0;
        (Application.getApp() as TactixApp).accentPrev();
    }

    private function _cancelUpTimer() as Void {
        if (mUpTimer != null) {
            mUpTimer.stop();
            mUpTimer = null;
        }
    }

    function onBack() as Boolean {
        var now = System.getTimer();
        if (now - mLastBackMs <= DOUBLE_PRESS_MS) {
            mLastBackMs = 0;
            _cancelBackTimer();
            pushNavMenu();
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
        // Режим акцента активен → одиночный BACK гасит акцент, не уходя на эко-экран.
        if (app.accentIndex >= 0) {
            app.accentOff();
            return;
        }
        app.suspendSensors();
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
            _cancelDownTimer();
            var view = new TimerView();
            WatchUi.pushView(view, new TimerDelegate(view), WatchUi.SLIDE_LEFT);
        } else {
            mLastDownMs = now;
            _cancelDownTimer();
            mDownTimer = new Timer.Timer();
            mDownTimer.start(method(:onSingleDown), DOUBLE_PRESS_MS + 50, false);
        }
        return true;
    }

    function onSingleDown() as Void {
        mDownTimer  = null;
        mLastDownMs = 0;
        (Application.getApp() as TactixApp).accentNext();
    }

    private function _cancelDownTimer() as Void {
        if (mDownTimer != null) {
            mDownTimer.stop();
            mDownTimer = null;
        }
    }

    function onSelect() as Boolean {
        var now = System.getTimer();
        if (now - mLastStartMs <= DOUBLE_PRESS_MS) {
            mLastStartMs = 0;
            _cancelStartTimer();
            WatchUi.pushView(new StopwatchListView(), new StopwatchListDelegate(),
                             WatchUi.SLIDE_LEFT);
        } else {
            mLastStartMs = now;
            _cancelStartTimer();
            mStartTimer = new Timer.Timer();
            mStartTimer.start(method(:onSingleStart), DOUBLE_PRESS_MS + 50, false);
        }
        return true;
    }

    function onSingleStart() as Void {
        mStartTimer  = null;
        mLastStartMs = 0;
        (Application.getApp() as TactixApp).toggleGps();
        WatchUi.requestUpdate();
    }

    private function _cancelStartTimer() as Void {
        if (mStartTimer != null) {
            mStartTimer.stop();
            mStartTimer = null;
        }
    }

    function onMenu() as Boolean {
        pushHelp(:main);
        return true;
    }
}
