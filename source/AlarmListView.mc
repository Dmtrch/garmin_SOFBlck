import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class AlarmListView extends WatchUi.View {
    var selectedIdx as Number = 0;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 18, Graphics.FONT_SMALL, "Будильники",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var alarms  = AlarmManager.load();
        var listTop = 38;
        var itemH   = (h - listTop - 4) / AlarmManager.MAX;

        for (var i = 0; i < AlarmManager.MAX; i++) {
            var a    = alarms[i] as Dictionary;
            var iy   = listTop + i * itemH;
            var midY = iy + itemH / 2;

            if (i == selectedIdx) {
                dc.setColor(0x003366, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(14, iy + 1, w - 28, itemH - 2, 5);
            }

            var en    = a["enabled"] as Boolean;
            var hStr  = (a["hour"] as Number).format("%02d");
            var mStr  = (a["min"] as Number).format("%02d");
            var label = (i + 1).format("%d") + ".  " + hStr + ":" + mStr + "  " + (en ? "ON" : "OFF");

            if (en) {
                if (a["vibe"] as Boolean)  { label = label + " V"; }
                if (a["sound"] as Boolean) { label = label + "S"; }
            }

            var color = (i == selectedIdx)
                ? Graphics.COLOR_YELLOW
                : (en ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY, Graphics.FONT_XTINY, label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
