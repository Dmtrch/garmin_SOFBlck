import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function pushNavMenu() as Void {
    var rus  = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
    var menu = new WatchUi.Menu2({:title => rus ? "Навигация" : "Navigation"});
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Компас: вкл/выкл" : "Compass: on/off", null, :compass, null));
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Установить метку" : "Set waypoint", null, :setWp, null));
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Направление на метку" : "Bearing to waypoint", null, :bearing, null));
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Список меток" : "Waypoint list", null, :list, null));
    menu.addItem(new WatchUi.MenuItem(
        rus ? "Справка" : "Help", null, :help, null));
    WatchUi.pushView(menu, new NavMenuDelegate(), WatchUi.SLIDE_UP);
}

class NavMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :compass) {
            (Application.getApp() as TactixApp).toggleCompass();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
            return;
        }
        if (id == :setWp) {
            pushWaypointMenu();
            return;
        }
        if (id == :bearing) {
            pushWaypointList(:pickForBearing);
            return;
        }
        if (id == :list) {
            pushWaypointList(:manage);
            return;
        }
        if (id == :help) {
            pushHelp(:navMenu);
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
