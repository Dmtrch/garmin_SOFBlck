import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

function pushWaypointList(mode as Symbol) as Void {
    var view = new WaypointListView(mode);
    WatchUi.pushView(view, new WaypointListDelegate(view), WatchUi.SLIDE_LEFT);
}

class WaypointListView extends WatchUi.View {
    var selectedIdx as Number = 0;
    var mode        as Symbol;

    function initialize(mode as Symbol) {
        View.initialize();
        self.mode = mode;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w   = dc.getWidth();
        var h   = dc.getHeight();
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
        var wps = NavManager.load();

        if (wps.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL,
                        rus ? "Нет меток" : "No waypoints",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var title = (mode == :pickForDelete)
            ? (rus ? "Удалить метку" : "Delete waypoint")
            : (rus ? "Направление на" : "Bearing to");
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 8, Graphics.FONT_XTINY, title,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Distance from current GPS position
        var posInfo  = Position.getInfo();
        var hasPos   = (posInfo != null && posInfo.position != null &&
                        posInfo.accuracy >= Position.QUALITY_POOR);
        var curCoords = hasPos
            ? (posInfo.position as Position.Location).toDegrees()
            : null;

        var font    = Graphics.FONT_XTINY;
        var fontH   = Graphics.getFontHeight(font);
        var topPad  = 26;
        var rowH    = fontH + 4;
        var maxRows = (h - topPad) / rowH;
        if (maxRows < 1) { maxRows = 1; }

        var n      = wps.size();
        var topIdx = selectedIdx - maxRows / 2;
        if (topIdx > n - maxRows) { topIdx = n - maxRows; }
        if (topIdx < 0)           { topIdx = 0; }

        for (var i = topIdx; i < n && i < topIdx + maxRows; i++) {
            var wp    = wps[i] as Dictionary;
            var name  = wp["name"] as String;

            var distStr = "--";
            if (curCoords != null) {
                var d = NavManager.distanceM(
                    curCoords[0] as Double, curCoords[1] as Double,
                    wp["lat"] as Double, wp["lon"] as Double);
                distStr = d < 10000.0f
                    ? d.format("%d") + "m"
                    : (d / 1000.0f).format("%.1f") + "km";
            }

            var label = (i + 1).format("%d") + ". " + name + "  " + distStr;
            var rowY  = topPad + (i - topIdx) * rowH;

            if (i == selectedIdx) {
                dc.setColor(0x003366, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(2, rowY, w - 4, rowH, 4);
            }

            var color = (i == selectedIdx) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, rowY + rowH / 2, font, label,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class WaypointListDelegate extends NoTouchDelegate {
    private var mView as WaypointListView;

    function initialize(view as WaypointListView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {
        var n = NavManager.load().size();
        if (n == 0) { WatchUi.popView(WatchUi.SLIDE_RIGHT); return true; }
        mView.selectedIdx = (mView.selectedIdx + n - 1) % n;
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        var n = NavManager.load().size();
        if (n == 0) { WatchUi.popView(WatchUi.SLIDE_RIGHT); return true; }
        mView.selectedIdx = (mView.selectedIdx + 1) % n;
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var wps = NavManager.load();
        var idx = mView.selectedIdx;
        if (idx < 0 || idx >= wps.size()) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }

        if (mView.mode == :pickForDelete) {
            NavManager.removeAt(idx);
            var remaining = NavManager.load().size();
            if (remaining == 0) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
            } else {
                if (mView.selectedIdx >= remaining) {
                    mView.selectedIdx = remaining - 1;
                }
                WatchUi.requestUpdate();
            }
        } else { // :pickForBearing — pop list + nav menu → main
            (Application.getApp() as TactixApp).startBearing(idx);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
