import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class TimerNotificationView extends WatchUi.View {
    private var mTimerNum as Number;

    function initialize(timerNum as Number) {
        View.initialize();
        mTimerNum = timerNum;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0x001a00, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, w / 2);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawCircle(cx, cy, w / 2 - 4);
        dc.setPenWidth(1);

        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
        var label = rus
            ? "ТАЙМЕР " + mTimerNum.format("%d")
            : "TIMER " + mTimerNum.format("%d");

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 52, Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var doneStr = rus ? "ГОТОВО" : "DONE";
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_HOT, doneStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 60, Graphics.FONT_XTINY, "START — выключить",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
