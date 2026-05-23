import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function pushWaypointEdit() as Void {
    var view = new WaypointEditView();
    WatchUi.pushView(view, new WaypointEditDelegate(view), WatchUi.SLIDE_LEFT);
}

// Fields 0..14 (15 шт.), редактируется каждая цифра отдельно:
//   0       — latSign  (N/S toggle)
//   1..2    — latDeg цифры [10s, 1s]
//   3..6    — latFrac цифры [1000s, 100s, 10s, 1s]
//   7       — lonSign  (E/W toggle)
//   8..10   — lonDeg цифры [100s, 10s, 1s]
//   11..14  — lonFrac цифры [1000s, 100s, 10s, 1s]
class WaypointEditView extends WatchUi.View {
    static const FIELD_MAX as Number = 14;

    var field   as Number = 0;
    var latSign as Number = 1;   // +1 = N, -1 = S
    var latDeg  as Number = 0;   // 0..90
    var latFrac as Number = 0;   // 0..9999 → .0000..9999
    var lonSign as Number = 1;   // +1 = E, -1 = W
    var lonDeg  as Number = 0;   // 0..180
    var lonFrac as Number = 0;

    private var mScale as Float = 1.0f;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        mScale = dc.getWidth().toFloat() / 260.0f;
    }

    private function s(v as Number) as Number {
        return (v.toFloat() * mScale + 0.5f).toNumber();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w   = dc.getWidth();
        var h   = dc.getHeight();
        var cx  = w / 2;
        var cy  = h / 2;
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(100), Graphics.FONT_XTINY,
            rus ? "Новая метка" : "New waypoint",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(68), Graphics.FONT_XTINY,
            rus ? "Широта" : "Latitude",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Lat row: signField=0, degDigits 2 (start=1), fracDigits 4 (start=3)
        _drawRow(dc, cx, cy - s(48), latSign, latDeg, latFrac, 90,
                 ["N", "S"] as Array<String>, 0, 1, 2, 3, 4);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(8), Graphics.FONT_XTINY,
            rus ? "Долгота" : "Longitude",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Lon row: signField=7, degDigits 3 (start=8), fracDigits 4 (start=11)
        _drawRow(dc, cx, cy + s(12), lonSign, lonDeg, lonFrac, 180,
                 ["E", "W"] as Array<String>, 7, 8, 3, 11, 4);

        // Стрелка под активной строкой
        var arrowY = (field < 7) ? cy - s(30) : cy + s(30);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, arrowY, Graphics.FONT_XTINY, "^",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var lineH = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var y0    = cy + s(55);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y0,             Graphics.FONT_XTINY,
            rus ? "UP/DOWN: цифра 0-9" : "UP/DOWN: digit 0-9",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH,     Graphics.FONT_XTINY,
            rus ? "START: след.цифра" : "START: next digit",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH * 2, Graphics.FONT_XTINY,
            rus ? "BACK: отмена" : "BACK: cancel",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // signField — field-индекс знака;
    // degStartField, degDigits — стартовый field-индекс и кол-во цифр градусов;
    // fracStartField, fracDigits — аналогично для дробной части.
    private function _drawRow(dc as Graphics.Dc, cx as Number, rowY as Number,
                               signVal as Number, deg as Number, frac as Number,
                               maxDeg as Number, posLabels as Array<String>,
                               signField as Number,
                               degStartField as Number, degDigits as Number,
                               fracStartField as Number, fracDigits as Number) as Void {
        var font    = Graphics.FONT_SMALL;
        var signStr = (signVal > 0) ? posLabels[0] : posLabels[1];
        var degFmt  = (degDigits == 3) ? "%03d" : "%02d";
        var degStr  = deg.format(degFmt);
        var fracStr = frac.format("%04d");

        // Считаем общую ширину для центрирования
        var wSign = dc.getTextWidthInPixels(signStr + " ", font);
        var wDeg  = dc.getTextWidthInPixels(degStr, font);
        var wDot  = dc.getTextWidthInPixels(".", font);
        var wFrac = dc.getTextWidthInPixels(fracStr, font);
        var xPos  = cx - (wSign + wDeg + wDot + wFrac) / 2;

        // Знак (целиком, одно поле)
        dc.setColor((field == signField) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, signStr + " ",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wSign;

        // Градусы — по одной цифре, каждая своим цветом
        xPos = _drawDigits(dc, xPos, rowY, font, degStr, degStartField);

        // Точка
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, ".",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wDot;

        // Дробная часть — по одной цифре
        _drawDigits(dc, xPos, rowY, font, fracStr, fracStartField);
    }

    // Рисует строку цифр по одной, активную (field == startField + i) — жёлтым.
    // Возвращает новую X-координату после строки.
    private function _drawDigits(dc as Graphics.Dc, x as Number, y as Number,
                                  font as Graphics.FontType, str as String,
                                  startField as Number) as Number {
        var chars = str.toCharArray();
        var pos = x;
        for (var i = 0; i < chars.size(); i++) {
            var ch  = chars[i].toString();
            var col = (field == startField + i) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.drawText(pos, y, font, ch,
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            pos += dc.getTextWidthInPixels(ch, font);
        }
        return pos;
    }
}

class WaypointEditDelegate extends NoTouchDelegate {
    private var mView as WaypointEditView;

    function initialize(view as WaypointEditView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {  // UP → +1
        _adjust(1);
        return true;
    }

    function onNextPage() as Boolean {  // DOWN → -1
        _adjust(-1);
        return true;
    }

    function onSelect() as Boolean {
        mView.field++;
        if (mView.field > WaypointEditView.FIELD_MAX) {
            _save();
        } else {
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onMenu() as Boolean {
        pushHelp(:waypointEdit);
        return true;
    }

    private function _adjust(delta as Number) as Void {
        var v = mView;
        var f = v.field;
        if (f == 0) { v.latSign = -v.latSign; }
        else if (f >= 1 && f <= 2) {
            // latDeg, цифра pos = f-1 (всего 2)
            v.latDeg = _adjustDigit(v.latDeg, f - 1, 2, delta, 90);
        }
        else if (f >= 3 && f <= 6) {
            // latFrac, цифра pos = f-3 (всего 4)
            v.latFrac = _adjustDigit(v.latFrac, f - 3, 4, delta, 9999);
        }
        else if (f == 7) { v.lonSign = -v.lonSign; }
        else if (f >= 8 && f <= 10) {
            // lonDeg, цифра pos = f-8 (всего 3)
            v.lonDeg = _adjustDigit(v.lonDeg, f - 8, 3, delta, 180);
        }
        else if (f >= 11 && f <= 14) {
            // lonFrac, цифра pos = f-11 (всего 4)
            v.lonFrac = _adjustDigit(v.lonFrac, f - 11, 4, delta, 9999);
        }
        WatchUi.requestUpdate();
    }

    // Меняет в value цифру в позиции pos (0 — самая левая) на delta,
    // циклически 0..9. После замены клэмпит результат в [0, max].
    private function _adjustDigit(value as Number, pos as Number, totalLen as Number,
                                   delta as Number, max as Number) as Number {
        var power = 1;
        for (var i = 0; i < totalLen - 1 - pos; i++) { power *= 10; }
        var oldDigit = (value / power) % 10;
        var newDigit = ((oldDigit + delta) % 10 + 10) % 10;
        var diff     = (newDigit - oldDigit) * power;
        var result   = value + diff;
        if (result < 0)   { result = 0; }
        if (result > max) { result = max; }
        return result;
    }

    private function _save() as Void {
        var v   = mView;
        var lat = v.latSign.toDouble() * (v.latDeg.toDouble() + v.latFrac.toDouble() / 10000.0d);
        var lon = v.lonSign.toDouble() * (v.lonDeg.toDouble() + v.lonFrac.toDouble() / 10000.0d);
        var newIdx = NavManager.add(lat, lon);
        // pop ×2: WaypointEdit + WaypointMenu → редактор имени (выход вернёт в NavMenu)
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        if (newIdx >= 0) {
            pushNameEdit(newIdx);
        }
    }
}
