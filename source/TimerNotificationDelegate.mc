import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TimerNotificationDelegate extends WatchUi.BehaviorDelegate {
    private var mIdx as Number;

    function initialize(idx as Number) {
        BehaviorDelegate.initialize();
        mIdx = idx;
    }

    function onSelect() as Boolean {
        var app = Application.getApp() as TactixApp;
        app.stopTimerNotification();
        app.resetTimerAt(mIdx);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        var app = Application.getApp() as TactixApp;
        app.stopTimerNotification();
        app.resetTimerAt(mIdx);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
