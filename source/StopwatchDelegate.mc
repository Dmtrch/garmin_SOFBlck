import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class StopwatchDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // START/STOP — toggle stopwatch
    function onSelect() as Boolean {
        (Application.getApp() as TactixApp).toggleStopwatch();
        WatchUi.requestUpdate();
        return true;
    }

    // DOWN — reset and exit
    function onNextPage() as Boolean {
        (Application.getApp() as TactixApp).resetStopwatch();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    // BACK — return to main, keep state
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
