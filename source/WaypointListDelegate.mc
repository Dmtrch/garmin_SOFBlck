import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

function pushWaypointList(mode as Symbol) as Void {
    var view = new WaypointListView(mode);
    WatchUi.pushView(view, new WaypointListDelegate(view), WatchUi.SLIDE_LEFT);
}

class WaypointListView extends WatchUi.View {
    var selectedIdx    as Number = 0;
    var mode           as Symbol;
    // Флаги выбора для multi-select в режиме :pickForBearing
    var selectedFlags  as Array<Boolean> = [] as Array<Boolean>;

    function initialize(mode as Symbol) {
        View.initialize();
        self.mode = mode;
        var n = NavManager.load().size();
        selectedFlags = new [n] as Array<Boolean>;
        for (var i = 0; i < n; i++) { selectedFlags[i] = false; }
        // Подсветить уже активные метки пеленга — чтобы их можно было снять.
        if (mode == :pickForBearing) {
            var app = Application.getApp() as TactixApp;
            if (app.bearingActive) {
                var active = app.bearingTargetIndices;
                for (var j = 0; j < active.size(); j++) {
                    var idx = active[j] as Number;
                    if (idx >= 0 && idx < n) {
                        selectedFlags[idx] = true;
                    }
                }
            }
        }
    }

    // Гарантирует, что размер selectedFlags соответствует текущему числу меток
    function ensureFlagsSize() as Void {
        var n = NavManager.load().size();
        if (selectedFlags.size() != n) {
            var newFlags = new [n] as Array<Boolean>;
            for (var i = 0; i < n; i++) {
                newFlags[i] = (i < selectedFlags.size())
                    ? (selectedFlags[i] as Boolean)
                    : false;
            }
            selectedFlags = newFlags;
        }
    }

    function selectedCount() as Number {
        var c = 0;
        for (var i = 0; i < selectedFlags.size(); i++) {
            if (selectedFlags[i] as Boolean) { c++; }
        }
        return c;
    }

    function collectIndices() as Array<Number> {
        var out = [] as Array<Number>;
        for (var i = 0; i < selectedFlags.size(); i++) {
            if (selectedFlags[i] as Boolean) { out.add(i); }
        }
        return out;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        ensureFlagsSize();

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

        var title;
        if (mode == :pickForDelete) {
            title = rus ? "Удалить метку" : "Delete waypoint";
        } else if (mode == :manage) {
            title = rus ? "Список меток" : "Waypoint list";
        } else {
            title = rus ? "Направление на" : "Bearing to";
        }
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 8, Graphics.FONT_XTINY, title,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Подсказка для multi-select + счётчик выбранных
        if (mode == :pickForBearing) {
            var cnt = selectedCount();
            var hint = rus
                ? "SEL: выбор   BACK: пуск (" + cnt.format("%d") + ")"
                : "SEL: pick   BACK: go (" + cnt.format("%d") + ")";
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h - 18, Graphics.FONT_XTINY, hint,
                        Graphics.TEXT_JUSTIFY_CENTER);
        } else if (mode == :manage) {
            var hint2 = rus
                ? "START×2: удалить"
                : "START×2: delete";
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h - 18, Graphics.FONT_XTINY, hint2,
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

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
        var bottomReserve = (mode == :pickForBearing || mode == :manage) ? 28 : 8;
        var rowH    = fontH + 4;
        var maxRows = (h - topPad - bottomReserve) / rowH;
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

            var isChecked = (mode == :pickForBearing) && (selectedFlags[i] as Boolean);
            var prefix = isChecked ? "* " : "  ";
            var label = prefix + (i + 1).format("%d") + ". " + name + "  " + distStr;
            var rowY  = topPad + (i - topIdx) * rowH;

            if (i == selectedIdx) {
                dc.setColor(0x003366, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(2, rowY, w - 4, rowH, 4);
            }

            var color = NavManager.colorFor(i);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, rowY + rowH / 2, font, label,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class WaypointListDelegate extends NoTouchDelegate {
    private static const DOUBLE_MS as Number = 500;

    private var mView         as WaypointListView;
    private var mLastSelectMs as Number = 0;

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
        } else if (mView.mode == :manage) {
            // Двойной START → подтверждение удаления.
            var now = System.getTimer();
            if (now - mLastSelectMs <= DOUBLE_MS) {
                mLastSelectMs = 0;
                pushConfirmDelete(idx);
            } else {
                mLastSelectMs = now;
            }
        } else { // :pickForBearing — toggle выбора метки
            mView.ensureFlagsSize();
            mView.selectedFlags[idx] = !(mView.selectedFlags[idx] as Boolean);
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onBack() as Boolean {
        if (mView.mode == :pickForBearing) {
            var app     = Application.getApp() as TactixApp;
            var indices = mView.collectIndices();
            if (indices.size() > 0) {
                // Запуск/обновление пеленга для выбранных меток → главный экран.
                app.startBearing(indices);
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            }
            // Если был активный пеленг и все метки сняты — остановить пеленг.
            if (app.bearingActive) {
                app.stopBearing();
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            }
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onMenu() as Boolean {
        if (mView.mode == :manage) {
            pushHelp(:waypointManage);
        } else {
            pushHelp(:waypointList);
        }
        return true;
    }
}
