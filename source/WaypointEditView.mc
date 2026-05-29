import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

function pushWaypointEdit() as Void {
    var view = new WaypointEditView();
    WatchUi.pushView(view, new WaypointEditDelegate(view), WatchUi.SLIDE_LEFT);
}

// === Режим DD.DDDDD (field 0..16) ===
//   0       — latSign
//   1..2    — latDeg  (2 цифры, 0..90)
//   3..7    — latFrac (5 цифр, 0..99999)
//   8       — lonSign
//   9..11   — lonDeg  (3 цифры, 0..180)
//   12..16  — lonFrac (5 цифр, 0..99999)
//
// === Режим DD°MM'SS.ss (field 0..18) ===
//   0       — latSign
//   1..2    — latDeg    (2 цифры, 0..90)
//   3..4    — latMin    (2 цифры, 0..59)
//   5..6    — latSec    (2 цифры, 0..59)
//   7..8    — latSecFrac(2 цифры, 0..99)
//   9       — lonSign
//   10..12  — lonDeg    (3 цифры, 0..180)
//   13..14  — lonMin    (2 цифры, 0..59)
//   15..16  — lonSec    (2 цифры, 0..59)
//   17..18  — lonSecFrac(2 цифры, 0..99)

class WaypointEditView extends WatchUi.View {
    static const FIELD_MAX_DD  as Number = 16;
    static const FIELD_MAX_DMS as Number = 18;

    var modeDMS as Boolean = false;

    // DD.DDDD
    var field   as Number = 0;
    var latSign as Number = 1;   // +1 = N, -1 = S
    var latDeg  as Number = 0;   // 0..90
    var latFrac as Number = 0;   // 0..99999
    var lonSign as Number = 1;   // +1 = E, -1 = W
    var lonDeg  as Number = 0;   // 0..180
    var lonFrac as Number = 0;

    // DD°MM'SS.s
    var latMin     as Number = 0;  // 0..59
    var latSec     as Number = 0;  // 0..59
    var latSecFrac as Number = 0;  // 0..99
    var lonMin     as Number = 0;
    var lonSec     as Number = 0;
    var lonSecFrac as Number = 0; // 0..99

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

    // Переключение формата с конвертацией текущих значений
    function toggleMode() as Void {
        if (!modeDMS) {
            // DD.DDDD → DD°MM'SS.s
            var f = latFrac.toDouble() / 100000.0d;
            var mTotal = f * 60.0d;
            latMin = mTotal.toNumber();
            var sTotal = (mTotal - latMin.toDouble()) * 60.0d;
            latSec = sTotal.toNumber();
            latSecFrac = ((sTotal - latSec.toDouble()) * 100.0d + 0.5d).toNumber();
            _normalizeDMS(latMin, latSec, latSecFrac, :lat);

            f = lonFrac.toDouble() / 100000.0d;
            mTotal = f * 60.0d;
            lonMin = mTotal.toNumber();
            sTotal = (mTotal - lonMin.toDouble()) * 60.0d;
            lonSec = sTotal.toNumber();
            lonSecFrac = ((sTotal - lonSec.toDouble()) * 100.0d + 0.5d).toNumber();
            _normalizeDMS(lonMin, lonSec, lonSecFrac, :lon);

            modeDMS = true;
        } else {
            // DD°MM'SS.s → DD.DDDD
            var decLat = latMin.toDouble() / 60.0d +
                         (latSec.toDouble() + latSecFrac.toDouble() / 100.0d) / 3600.0d;
            latFrac = (decLat * 100000.0d + 0.5d).toNumber();
            if (latFrac > 99999) { latFrac = 99999; }

            var decLon = lonMin.toDouble() / 60.0d +
                         (lonSec.toDouble() + lonSecFrac.toDouble() / 100.0d) / 3600.0d;
            lonFrac = (decLon * 100000.0d + 0.5d).toNumber();
            if (lonFrac > 99999) { lonFrac = 99999; }

            modeDMS = false;
        }
        field = 0;
        WatchUi.requestUpdate();
    }

    // Нормализует переполнение: secFrac≥10 → sec++, sec≥60 → min++
    private function _normalizeDMS(mn as Number, sc as Number, sf as Number,
                                    which as Symbol) as Void {
        if (sf >= 100) { sf = sf - 100; sc++; }
        if (sc >= 60) { sc = 59; sf = 9; }
        if (mn >= 60) { mn = 59; }
        if (which == :lat) {
            latMin = mn; latSec = sc; latSecFrac = sf;
        } else {
            lonMin = mn; lonSec = sc; lonSecFrac = sf;
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w   = dc.getWidth();
        var h   = dc.getHeight();
        var cx  = w / 2;
        var cy  = h / 2;
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // GPS-фикс справочно
        var posInfo = Position.getInfo();
        var gpsStr  = "";
        if (posInfo == null || posInfo.position == null) {
            gpsStr = "GPS: --";
        } else {
            var coords = (posInfo.position as Position.Location).toDegrees();
            gpsStr = "GPS: " + (coords[0] as Double).format("%.5f") + "  " +
                     (coords[1] as Double).format("%.5f");
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(80), Graphics.FONT_XTINY, gpsStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(63), Graphics.FONT_XTINY,
            rus ? "Новая метка" : "New waypoint",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(38), Graphics.FONT_XTINY,
            rus ? "Широта" : "Latitude",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (!modeDMS) {
            _drawRow(dc, cx, cy - s(18), latSign, latDeg, latFrac, 90,
                     ["N", "S"] as Array<String>, 0, 1, 2, 3, 5);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + s(22), Graphics.FONT_XTINY,
                rus ? "Долгота" : "Longitude",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            _drawRow(dc, cx, cy + s(42), lonSign, lonDeg, lonFrac, 180,
                     ["E", "W"] as Array<String>, 8, 9, 3, 12, 5);
        } else {
            _drawRowDMS(dc, cx, cy - s(18), latSign, latDeg, latMin, latSec, latSecFrac,
                        ["N", "S"] as Array<String>, 0, 1, 3, 5, 7);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + s(22), Graphics.FONT_XTINY,
                rus ? "Долгота" : "Longitude",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            _drawRowDMS(dc, cx, cy + s(42), lonSign, lonDeg, lonMin, lonSec, lonSecFrac,
                        ["E", "W"] as Array<String>, 9, 10, 13, 15, 17);
        }

        // Метка формата — на 10 пикселей ниже строки долготы
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + s(42) + 30, Graphics.FONT_XTINY,
            modeDMS ? "DD°MM'SS.ss\"" : "DD.DDDDD°",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Стрелка под активной строкой
        var latFieldMax = modeDMS ? 8 : 7;
        var arrowY = (field <= latFieldMax) ? cy : cy + s(60);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, arrowY, Graphics.FONT_XTINY, "^",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // DD.DDDD строка
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
        var fracStr = frac.format("%05d");

        var wSign = dc.getTextWidthInPixels(signStr + " ", font);
        var wDeg  = dc.getTextWidthInPixels(degStr, font);
        var wDot  = dc.getTextWidthInPixels(".", font);
        var wFrac = dc.getTextWidthInPixels(fracStr, font);
        var xPos  = cx - (wSign + wDeg + wDot + wFrac) / 2;

        dc.setColor((field == signField) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, signStr + " ",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wSign;

        xPos = _drawDigits(dc, xPos, rowY, font, degStr, degStartField);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, ".",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wDot;

        _drawDigits(dc, xPos, rowY, font, fracStr, fracStartField);
    }

    // DD°MM'SS.s" N строка (знак справа)
    // signFld — field знака; degFld, minFld, secFld, sfFld — стартовые field цифр
    private function _drawRowDMS(dc as Graphics.Dc, cx as Number, rowY as Number,
                                  signVal as Number, deg as Number,
                                  mn as Number, sc as Number, sf as Number,
                                  posLabels as Array<String>,
                                  signFld as Number, degFld as Number,
                                  minFld as Number, secFld as Number,
                                  sfFld as Number) as Void {
        var font    = Graphics.FONT_SMALL;
        var signStr = (signVal > 0) ? posLabels[0] : posLabels[1];
        var degDigits = (signFld == 9) ? 3 : 2;  // lon → 3 цифры
        var degFmt  = (degDigits == 3) ? "%03d" : "%02d";
        var degStr  = deg.format(degFmt);
        var minStr  = mn.format("%02d");
        var secStr  = sc.format("%02d");
        var sfStr   = sf.format("%02d");

        var sep1 = "°";
        var sep2 = "'";
        var sep3 = ".";
        var sep4 = "\"";

        var wSign = dc.getTextWidthInPixels(" " + signStr, font);
        var wDeg  = dc.getTextWidthInPixels(degStr, font);
        var wS1   = dc.getTextWidthInPixels(sep1, font);
        var wMin  = dc.getTextWidthInPixels(minStr, font);
        var wS2   = dc.getTextWidthInPixels(sep2, font);
        var wSec  = dc.getTextWidthInPixels(secStr, font);
        var wS3   = dc.getTextWidthInPixels(sep3, font);
        var wSf   = dc.getTextWidthInPixels(sfStr, font);
        var wS4   = dc.getTextWidthInPixels(sep4, font);

        // Формат: DD°MM'SS.s" N
        var total = wDeg + wS1 + wMin + wS2 + wSec + wS3 + wSf + wS4 + wSign;
        var xPos  = cx - total / 2;

        // Градусы
        xPos = _drawDigits(dc, xPos, rowY, font, degStr, degFld);

        // °
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, sep1,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wS1;

        // Минуты
        xPos = _drawDigits(dc, xPos, rowY, font, minStr, minFld);

        // '
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, sep2,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wS2;

        // Секунды
        xPos = _drawDigits(dc, xPos, rowY, font, secStr, secFld);

        // .
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, sep3,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wS3;

        // Десятые секунды
        xPos = _drawDigits(dc, xPos, rowY, font, sfStr, sfFld);

        // "
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, sep4,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wS4;

        // Знак справа
        dc.setColor((field == signFld) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, " " + signStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

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
    private var mView        as WaypointEditView;
    private var mLastNextMs  as Number       = 0;
    private var mNextTimer   as Timer.Timer? = null;

    function initialize(view as WaypointEditView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {
        _adjust(1);
        return true;
    }

    function onNextPage() as Boolean {
        var now = System.getTimer();
        if (mLastNextMs > 0 && now - mLastNextMs < 400) {
            // двойное нажатие — переключить формат
            if (mNextTimer != null) { mNextTimer.stop(); mNextTimer = null; }
            mLastNextMs = 0;
            mView.toggleMode();
        } else {
            // первое нажатие — ждём второго
            mLastNextMs = now;
            mNextTimer = new Timer.Timer();
            mNextTimer.start(method(:_onNextSingle), 400, false);
        }
        return true;
    }

    function _onNextSingle() as Void {
        mNextTimer  = null;
        mLastNextMs = 0;
        _adjust(-1);
    }

    function onSelect() as Boolean {
        var maxField = mView.modeDMS ? WaypointEditView.FIELD_MAX_DMS
                                     : WaypointEditView.FIELD_MAX_DD;
        mView.field++;
        if (mView.field > maxField) {
            _save();
        } else {
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onBack() as Boolean {
        if (mView.field > 0) {
            mView.field--;
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onMenu() as Boolean {
        pushHelp(:waypointEdit);
        return true;
    }

    private function _adjust(delta as Number) as Void {
        var v = mView;
        var f = v.field;
        if (!v.modeDMS) {
            _adjustDD(v, f, delta);
        } else {
            _adjustDMS(v, f, delta);
        }
        WatchUi.requestUpdate();
    }

    private function _adjustDD(v as WaypointEditView, f as Number, delta as Number) as Void {
        if (f == 0) { v.latSign = -v.latSign; }
        else if (f >= 1 && f <= 2) {
            v.latDeg = _adjustDigit(v.latDeg, f - 1, 2, delta, 90);
        }
        else if (f >= 3 && f <= 7) {
            v.latFrac = _adjustDigit(v.latFrac, f - 3, 5, delta, 99999);
        }
        else if (f == 8) { v.lonSign = -v.lonSign; }
        else if (f >= 9 && f <= 11) {
            v.lonDeg = _adjustDigit(v.lonDeg, f - 9, 3, delta, 180);
        }
        else if (f >= 12 && f <= 16) {
            v.lonFrac = _adjustDigit(v.lonFrac, f - 12, 5, delta, 99999);
        }
    }

    private function _adjustDMS(v as WaypointEditView, f as Number, delta as Number) as Void {
        if (f == 0) { v.latSign = -v.latSign; }
        else if (f >= 1 && f <= 2) {
            v.latDeg = _adjustDigit(v.latDeg, f - 1, 2, delta, 90);
        }
        else if (f >= 3 && f <= 4) {
            v.latMin = _adjustDigit(v.latMin, f - 3, 2, delta, 59);
        }
        else if (f >= 5 && f <= 6) {
            v.latSec = _adjustDigit(v.latSec, f - 5, 2, delta, 59);
        }
        else if (f >= 7 && f <= 8) {
            v.latSecFrac = _adjustDigit(v.latSecFrac, f - 7, 2, delta, 99);
        }
        else if (f == 9) { v.lonSign = -v.lonSign; }
        else if (f >= 10 && f <= 12) {
            v.lonDeg = _adjustDigit(v.lonDeg, f - 10, 3, delta, 180);
        }
        else if (f >= 13 && f <= 14) {
            v.lonMin = _adjustDigit(v.lonMin, f - 13, 2, delta, 59);
        }
        else if (f >= 15 && f <= 16) {
            v.lonSec = _adjustDigit(v.lonSec, f - 15, 2, delta, 59);
        }
        else if (f >= 17 && f <= 18) {
            v.lonSecFrac = _adjustDigit(v.lonSecFrac, f - 17, 2, delta, 99);
        }
    }

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
        var lat = v.modeDMS
            ? v.latSign.toDouble() * (v.latDeg.toDouble()
                  + v.latMin.toDouble() / 60.0d
                  + (v.latSec.toDouble() + v.latSecFrac.toDouble() / 100.0d) / 3600.0d)
            : v.latSign.toDouble() * (v.latDeg.toDouble() + v.latFrac.toDouble() / 100000.0d);
        var lon = v.modeDMS
            ? v.lonSign.toDouble() * (v.lonDeg.toDouble()
                  + v.lonMin.toDouble() / 60.0d
                  + (v.lonSec.toDouble() + v.lonSecFrac.toDouble() / 100.0d) / 3600.0d)
            : v.lonSign.toDouble() * (v.lonDeg.toDouble() + v.lonFrac.toDouble() / 100000.0d);
        var confirmView = new WaypointConfirmView(lat, lon);
        WatchUi.pushView(confirmView, new WaypointConfirmDelegate(confirmView), WatchUi.SLIDE_LEFT);
    }
}
