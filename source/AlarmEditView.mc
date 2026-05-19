import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class AlarmEditView extends WatchUi.View {
    var hour  as Number;
    var min   as Number;
    var field as Number = 0; // 0 = hour, 1 = min
    private var mIdx as Number;

    function initialize(idx as Number, h as Number, m as Number) {
        View.initialize();
        mIdx = idx;
        hour = h;
        min  = m;
    }

    function getIdx() as Number { return mIdx; }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth()  / 2;
        var cy = dc.getHeight() / 2;

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 68, Graphics.FONT_SMALL,
            "Будильник " + (mIdx + 1).format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Hour (right-aligned to center)
        dc.setColor(field == 0 ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 6, cy, Graphics.FONT_NUMBER_HOT, hour.format("%02d"),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Colon
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 6, Graphics.FONT_MEDIUM, ":",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Minute (left-aligned from center)
        dc.setColor(field == 1 ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 6, cy, Graphics.FONT_NUMBER_HOT, min.format("%02d"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Field indicator arrow
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        var fontH = Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT);
        var arrowX = (field == 0) ? cx - 6 : cx + 6;
        var arrowJust = (field == 0)
            ? Graphics.TEXT_JUSTIFY_RIGHT
            : Graphics.TEXT_JUSTIFY_LEFT;
        dc.drawText(arrowX, cy + fontH / 2 + 4, Graphics.FONT_XTINY, "^^^", arrowJust);

        // Hints
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 68, Graphics.FONT_XTINY,
            "UP/DOWN: знач.  START: поле  BACK: сохр.",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
