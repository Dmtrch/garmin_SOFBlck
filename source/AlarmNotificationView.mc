import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class AlarmNotificationView extends WatchUi.View {
    private var mHour as Number;
    private var mMin  as Number;

    function initialize(hour as Number, min as Number) {
        View.initialize();
        mHour = hour;
        mMin  = min;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Тёмно-красный фон-круг
        dc.setColor(0x220000, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, w / 2);

        // Красная рамка
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawCircle(cx, cy, w / 2 - 4);
        dc.setPenWidth(1);

        // Надпись "БУДИЛЬНИК"
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 52, Graphics.FONT_SMALL, "БУДИЛЬНИК",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Время будильника крупно
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var timeStr = mHour.format("%02d") + ":" + mMin.format("%02d");
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Подсказка выключения
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 60, Graphics.FONT_XTINY, "BACK — выключить",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
