import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class TimerDelegate extends NoTouchDelegate {

    private static const DOUBLE_MS as Number = 500;

    private var mView         as TimerView;
    private var mLastSelectMs as Number       = 0;
    private var mPendingTimer as Timer.Timer? = null;

    function initialize(view as TimerView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {
        if (mView.mSetupMode) {
            mView.bumpField(1);
        } else {
            _cancelPending();
            var app = Application.getApp() as TactixApp;
            app.tmSelectedIdx = (app.tmSelectedIdx + 4) % 5;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        if (mView.mSetupMode) {
            mView.bumpField(-1);
        } else {
            _cancelPending();
            var app = Application.getApp() as TactixApp;
            app.tmSelectedIdx = (app.tmSelectedIdx + 1) % 5;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        if (mView.mSetupMode) {
            var moved = mView.gotoNextField();
            if (!moved) {
                var durationMs = mView.getSetupDurationMs();
                if (durationMs > 0) {
                    var app = Application.getApp() as TactixApp;
                    app.startTimerAt(app.tmSelectedIdx, durationMs);
                    mView.mSetupMode = false;
                }
            }
            WatchUi.requestUpdate();
            return true;
        }

        var now = System.getTimer();
        if (now - mLastSelectMs <= DOUBLE_MS) {
            mLastSelectMs = 0;
            _cancelPending();
            var app = Application.getApp() as TactixApp;
            app.resetTimerAt(app.tmSelectedIdx);
            WatchUi.requestUpdate();
        } else {
            mLastSelectMs = now;
            _cancelPending();
            mPendingTimer = new Timer.Timer();
            mPendingTimer.start(method(:onSingleSelect), DOUBLE_MS + 50, false);
        }
        return true;
    }

    function onSingleSelect() as Void {
        mPendingTimer = null;
        mLastSelectMs = 0;
        var app = Application.getApp() as TactixApp;
        var idx = app.tmSelectedIdx;
        if (app.tmExpired[idx] as Boolean) {
            app.resetTimerAt(idx);
        } else if (app.hasTimerAt(idx)) {
            app.toggleTimerPauseAt(idx);
        } else {
            mView.enterSetup();
        }
        WatchUi.requestUpdate();
    }

    function onBack() as Boolean {
        if (mView.mSetupMode) {
            var moved = mView.gotoPrevField();
            if (!moved) {
                mView.mSetupMode = false;
            }
            WatchUi.requestUpdate();
        } else {
            _cancelPending();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

    private function _cancelPending() as Void {
        if (mPendingTimer != null) {
            mPendingTimer.stop();
            mPendingTimer = null;
        }
    }
}
