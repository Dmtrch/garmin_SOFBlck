import Toybox.Lang;
import Toybox.WatchUi;

class NoTouchDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean { return true; }
    function onRelease(clickEvent as WatchUi.ClickEvent) as Boolean { return true; }
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean { return true; }
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean { return true; }
    function onFlick(flickEvent as WatchUi.FlickEvent) as Boolean { return true; }
    function onHold(clickEvent as WatchUi.ClickEvent) as Boolean { return true; }
}
