import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

class WaypointConfirmView extends WatchUi.View {
    var enteredLat as Double;
    var enteredLon as Double;

    function initialize(lat as Double, lon as Double) {
        View.initialize();
        enteredLat = lat;
        enteredLon = lon;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w   = dc.getWidth();
        var h   = dc.getHeight();
        var cx  = w / 2;
        var cy  = h / 2;
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var lineS = Graphics.getFontHeight(Graphics.FONT_SMALL) + 4;
        var lineT = Graphics.getFontHeight(Graphics.FONT_TINY)  + 4;

        // --- 1. Текущие GPS-координаты ---
        var posInfo  = Position.getInfo();
        var curLat   = 0.0d;
        var curLon   = 0.0d;
        var hasFix   = false;
        var curLabel = "";
        if (posInfo.position == null) {
            curLabel = "GPS: --";
        } else {
            var coords = (posInfo.position as Position.Location).toDegrees();
            curLat   = coords[0] as Double;
            curLon   = coords[1] as Double;
            hasFix   = true;
            curLabel = curLat.format("%.4f") + "  " + curLon.format("%.4f");
        }
        var yTop = cy - lineS - lineT - 8;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, yTop, Graphics.FONT_TINY,
            rus ? "Текущие:" : "Current:",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, yTop + lineT, Graphics.FONT_TINY, curLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- 2. Введённые координаты ---
        var entLabel = enteredLat.format("%.4f") + "  " + enteredLon.format("%.4f");
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - lineS / 2, Graphics.FONT_SMALL,
            rus ? "Введено:" : "Entered:",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + lineS / 2, Graphics.FONT_SMALL, entLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- 3. Дистанция ---
        var distLabel = "";
        if (!hasFix) {
            distLabel = "--";
        } else {
            var dm = NavManager.distanceM(curLat, curLon, enteredLat, enteredLon);
            if (dm >= 1000.0f) {
                distLabel = (dm / 1000.0f).format("%.1f") + " km";
            } else {
                distLabel = dm.format("%.0f") + " m";
            }
        }
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + lineS + lineS / 2 + 4, Graphics.FONT_SMALL,
            (rus ? "Дист: " : "Dist: ") + distLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    }
}

// Делегат для ввода имени метки через TextPicker
class WaypointNamePickerDelegate extends WatchUi.TextPickerDelegate {
    private var mWpIdx as Number;

    function initialize(wpIdx as Number) {
        TextPickerDelegate.initialize();
        mWpIdx = wpIdx;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (changed && text.length() > 0) {
            NavManager.rename(mWpIdx, text);
        }
        // pop TextPicker + WaypointConfirmView → возврат в WaypointEditView не нужен,
        // поэтому попаем ещё раз чтобы убрать и редактор
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

class WaypointConfirmDelegate extends NoTouchDelegate {
    private var mView as WaypointConfirmView;

    function initialize(view as WaypointConfirmView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onMenu() as Boolean {
        pushHelp(:waypointConfirm);
        return true;
    }

    function onSelect() as Boolean {
        _doSave();
        return true;
    }

    private function _doSave() as Void {
        var lat    = mView.enteredLat;
        var lon    = mView.enteredLon;
        var newIdx = NavManager.add(lat, lon);
        if (newIdx >= 0) {
            var picker = new WatchUi.TextPicker("");
            WatchUi.pushView(picker, new WaypointNamePickerDelegate(newIdx), WatchUi.SLIDE_UP);
        } else {
            // MAX меток достигнут — просто закрываем confirm + edit
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
