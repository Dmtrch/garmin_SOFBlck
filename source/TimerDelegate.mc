import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TimerDelegate extends WatchUi.BehaviorDelegate {

    private var mView as TimerView;

    function initialize(view as TimerView) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onSelect() as Boolean {
        var app = Application.getApp() as TactixApp;
        if (mView.mSetupMode) {
            // Confirm field; on last field — start timer
            var moved = mView.gotoNextField();
            if (!moved) {
                var durationMs = mView.getSetupDurationMs();
                if (durationMs > 0) {
                    app.startTimer(durationMs);
                    mView.mSetupMode = false;
                }
            }
        } else {
            app.toggleTimerPause();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        if (mView.mSetupMode) {
            // Previous field; if already on first — exit to main
            var moved = mView.gotoPrevField();
            if (!moved) {
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            } else {
                WatchUi.requestUpdate();
            }
        } else {
            // Active timer — return to main, state preserved
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        if (mView.mSetupMode) {
            mView.bumpField(1);
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onNextPage() as Boolean {
        var app = Application.getApp() as TactixApp;
        if (mView.mSetupMode) {
            mView.bumpField(-1);
            WatchUi.requestUpdate();
        } else {
            // Active timer mode — reset and exit
            app.resetTimer();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}
