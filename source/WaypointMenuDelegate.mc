import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

function pushWaypointMenu() as Void {
    var rus  = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
    var menu = new WatchUi.Menu2({:title => rus ? "Установить метку" : "Set waypoint"});
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Текущие координаты" : "Current coordinates", null, :current, null));
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Ввести вручную" : "Enter manually", null, :manual, null));
    if (Toybox has :Map) {
        menu.addItem(new WatchUi.MenuItem(
            rus ? "Указать на карте" : "Pick on map", null, :map, null));
    }
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Удалить метку" : "Delete waypoint", null, :delete, null));
    WatchUi.pushView(menu, new WaypointMenuDelegate(), WatchUi.SLIDE_LEFT);
}

class WaypointMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id  = item.getId();
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        if (id == :current) {
            var posInfo = Position.getInfo();
            if (posInfo.position == null || posInfo.accuracy < Position.QUALITY_POOR) {
                var msg = rus ? "Нет фикса GPS" : "No GPS fix";
                WatchUi.pushView(new _NavMsgView(msg), new _NavMsgDelegate(), WatchUi.SLIDE_UP);
                return;
            }
            var coords = (posInfo.position as Position.Location).toDegrees();
            if (!NavManager.add(coords[0] as Double, coords[1] as Double)) {
                var msg = rus ? "Максимум меток" : "Max waypoints";
                WatchUi.pushView(new _NavMsgView(msg), new _NavMsgDelegate(), WatchUi.SLIDE_UP);
                return;
            }
            // pop WaypointMenu + NavMenu → main screen
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }

        if (id == :manual) {
            pushWaypointEdit();
            return;
        }

        if (id == :map) {
            // placeholder — MapPickView (future stage)
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }

        if (id == :delete) {
            pushWaypointList(:pickForDelete);
            return;
        }

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

}

// Lightweight one-line message overlay, dismissed by any button press.
class _NavMsgView extends WatchUi.View {
    private var mMsg as String;
    function initialize(msg as String) {
        View.initialize();
        mMsg = msg;
    }
    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL, mMsg,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class _NavMsgDelegate extends NoTouchDelegate {
    function initialize() { NoTouchDelegate.initialize(); }
    function onBack()         as Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
    function onSelect()       as Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
    function onPreviousPage() as Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
    function onNextPage()     as Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
}
