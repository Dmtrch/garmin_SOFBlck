import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class AlarmListView extends WatchUi.View {
    var selectedIdx as Number = 0;

    function initialize() {
        View.initialize();
    }

    private function drawAlarmIcon(dc as Graphics.Dc, x as Number, y as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        dc.drawArc(x, y - r, r / 2, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        var fr = r / 5;
        if (fr < 2) { fr = 2; }
        dc.fillCircle(x - r / 2, y + r + fr, fr);
        dc.fillCircle(x + r / 2, y + r + fr, fr);
        dc.drawLine(x, y, x, y - r + 3);
        dc.drawLine(x, y, x + r * 2 / 3, y + r / 3);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w  = dc.getWidth();
        var h  = dc.getHeight();

        var iconR    = h / 12;
        var iconX    = iconR + 6;
        var iconY    = h / 2;
        drawAlarmIcon(dc, iconX, iconY, iconR);

        var listLeft = iconR * 2 + 14 - 20;
        if (listLeft < 0) { listLeft = 0; }
        var cx       = listLeft + (w - listLeft) / 2;

        var alarms  = AlarmManager.load();
        var pad     = 8;
        var itemH   = (h - pad * 2) / AlarmManager.MAX;
        var listTop = pad;

        for (var i = 0; i < AlarmManager.MAX; i++) {
            var a    = alarms[i] as Dictionary;
            var iy   = listTop + i * itemH;
            var midY = iy + itemH / 2;

            if (i == selectedIdx) {
                dc.setColor(0x003366, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(listLeft, iy + 1, w - listLeft - 4, itemH - 2, 5);
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
