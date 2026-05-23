import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TimerNotificationDelegate extends NoTouchDelegate {
    private var mIdx as Number;

    function initialize(idx as Number) {
        NoTouchDelegate.initialize();
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

    function onMenu() as Boolean {
        pushHelp(:timerNotif);
        return true;
    }
}
