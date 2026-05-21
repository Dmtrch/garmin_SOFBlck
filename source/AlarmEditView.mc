import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
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
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 72, Graphics.FONT_SMALL,
            (rus ? "Будильник " : "Alarm ") + (mIdx + 1).format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Время: часы и минуты раздельно, двоеточие между ними
        var hColor = (field == 0) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        var mColor = (field == 1) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;

        dc.setColor(hColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 8, cy - 10, Graphics.FONT_NUMBER_HOT, hour.format("%02d"),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 16, Graphics.FONT_MEDIUM, ":",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(mColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 8, cy - 10, Graphics.FONT_NUMBER_HOT, min.format("%02d"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Индикатор активного поля — маленькие стрелки под нужной цифрой
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        var arrowX   = (field == 0) ? cx - 8 : cx + 8;
        var arrowJust = (field == 0)
            ? Graphics.TEXT_JUSTIFY_RIGHT
            : Graphics.TEXT_JUSTIFY_LEFT;
        dc.drawText(arrowX, cy + 30, Graphics.FONT_XTINY, "^ ^ ^", arrowJust);

        // Подсказка — 3 строки по центру
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var lineH = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var y0    = cy + 55;
        dc.drawText(cx, y0,          Graphics.FONT_XTINY, rus ? "UP / DOWN: значение" : "UP / DOWN: value",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH,  Graphics.FONT_XTINY, rus ? "START: поле" : "START: field",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH * 2, Graphics.FONT_XTINY, rus ? "BACK: сохранить" : "BACK: save",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
