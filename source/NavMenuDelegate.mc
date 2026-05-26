import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

// ── Заголовок меню: "Navigation" + GPS-индикатор ─────────────────────────────

class _NavHeader extends WatchUi.Drawable {
    function initialize() {
        Drawable.initialize({:identifier => "NavHeader", :height => 70});
    }

    function draw(dc as Graphics.Dc) as Void {
        var w   = dc.getWidth();
        var cx  = w / 2;
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 20, Graphics.FONT_SMALL,
                    rus ? "Навигация" : "Navigation",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // GPS-индикатор. Зелёный только при реальном фиксе (>= QUALITY_POOR);
        // QUALITY_LAST_KNOWN — кэш часов, фикса ещё нет.
        var posInfo = Position.getInfo();
        var hasGps  = (posInfo != null
                       && posInfo.position != null
                       && posInfo.accuracy != null
                       && posInfo.accuracy >= Position.QUALITY_POOR);
        dc.setColor(hasGps ? Graphics.COLOR_GREEN : Graphics.COLOR_RED,
                    Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, 52, 5);
    }
}

// ── Пункт меню ────────────────────────────────────────────────────────────────

class _NavItem extends WatchUi.CustomMenuItem {
    private var mText as String;

    function initialize(id as Symbol, label as String) {
        CustomMenuItem.initialize(id, {});
        mText = label;
    }

    function draw(dc as Graphics.Dc) as Void {
        var focused = isFocused();
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_TRANSPARENT);
        dc.clear();
        dc.setColor(focused ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL,
                    mText,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// ── Фабрика ───────────────────────────────────────────────────────────────────

function pushNavMenu() as Void {
    var app = Application.getApp() as TactixApp;
    var rus  = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
    var menu = new WatchUi.CustomMenu(50, Graphics.COLOR_BLACK, {:title => new _NavHeader()});
    menu.addItem(new _NavItem(:compass, rus ? "Компас: вкл/выкл"    : "Compass: on/off"));
    menu.addItem(new _NavItem(:setWp,   rus ? "Установить метку"     : "Set waypoint"));
    menu.addItem(new _NavItem(:bearing, rus ? "Направление на метку" : "Bearing to waypoint"));
    menu.addItem(new _NavItem(:list,    rus ? "Список меток"         : "Waypoint list"));
    menu.addItem(new _NavItem(:help,    rus ? "Справка"              : "Help"));
    WatchUi.pushView(menu, new NavMenuDelegate(), WatchUi.SLIDE_UP);
}

// ── Делегат ───────────────────────────────────────────────────────────────────

class NavMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :compass) {
            (Application.getApp() as TactixApp).toggleCompass();
            _exitToMain();
            WatchUi.requestUpdate();
            return;
        }
        if (id == :setWp)   { pushWaypointMenu();           return; }
        if (id == :bearing) { pushWaypointList(:pickForBearing); return; }
        if (id == :list)    { pushWaypointList(:manage);    return; }
        if (id == :help)    { pushHelp(:navMenu);           return; }
        _exitToMain();
    }

    function onBack() as Void {
        _exitToMain();
    }

    private function _exitToMain() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
