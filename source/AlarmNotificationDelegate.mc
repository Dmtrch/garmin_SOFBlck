import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class AlarmNotificationDelegate extends NoTouchDelegate {
    function initialize() {
        NoTouchDelegate.initialize();
    }

    function onSelect() as Boolean {
        (Application.getApp() as TactixApp).stopAlarmNotification();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        (Application.getApp() as TactixApp).stopAlarmNotification();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
