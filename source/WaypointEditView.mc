import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function pushWaypointEdit() as Void {
    var view = new WaypointEditView();
    WatchUi.pushView(view, new WaypointEditDelegate(view), WatchUi.SLIDE_LEFT);
}

// Fields 0..5: latSign, latDeg, latFrac, lonSign, lonDeg, lonFrac
class WaypointEditView extends WatchUi.View {
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

        _drawRow(dc, cx, cy - s(48), latSign, latDeg, latFrac, 90,
                 ["N", "S"] as Array<String>, 0);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(8), Graphics.FONT_XTINY,
            rus ? "Долгота" : "Longitude",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        _drawRow(dc, cx, cy + s(12), lonSign, lonDeg, lonFrac, 180,
                 ["E", "W"] as Array<String>, 3);

        // Arrow under active row
        var arrowY = (field < 3) ? cy - s(30) : cy + s(30);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, arrowY, Graphics.FONT_XTINY, "^ ^ ^",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var lineH = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var y0    = cy + s(55);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y0,             Graphics.FONT_XTINY,
            rus ? "UP/DOWN: значение" : "UP/DOWN: value",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH,     Graphics.FONT_XTINY,
            rus ? "START: след.поле" : "START: next field",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH * 2, Graphics.FONT_XTINY,
            rus ? "BACK: отмена" : "BACK: cancel",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _drawRow(dc as Graphics.Dc, cx as Number, rowY as Number,
                               signVal as Number, deg as Number, frac as Number,
                               maxDeg as Number, posLabels as Array<String>,
                               fieldBase as Number) as Void {
        var font    = Graphics.FONT_SMALL;
        var signStr = (signVal > 0) ? posLabels[0] : posLabels[1];
        var degStr  = (maxDeg == 180) ? deg.format("%03d") : deg.format("%02d");
        var fracStr = frac.format("%04d");

        var wSign = dc.getTextWidthInPixels(signStr + " ", font);
        var wDeg  = dc.getTextWidthInPixels(degStr, font);
        var wDot  = dc.getTextWidthInPixels(".", font);
        var wFrac = dc.getTextWidthInPixels(fracStr, font);
        var xPos  = cx - (wSign + wDeg + wDot + wFrac) / 2;

        dc.setColor((field == fieldBase    ) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, signStr + " ",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wSign;

        dc.setColor((field == fieldBase + 1) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, degStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wDeg;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, ".",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        xPos += wDot;

        dc.setColor((field == fieldBase + 2) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, rowY, font, fracStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
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
        if (mView.field > 5) {
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

    private function _adjust(delta as Number) as Void {
        var v = mView;
        if      (v.field == 0) { v.latSign = -v.latSign; }
        else if (v.field == 1) { v.latDeg  = _clamp(v.latDeg  + delta, 0, 90); }
        else if (v.field == 2) { v.latFrac = _clamp(v.latFrac + delta, 0, 9999); }
        else if (v.field == 3) { v.lonSign = -v.lonSign; }
        else if (v.field == 4) { v.lonDeg  = _clamp(v.lonDeg  + delta, 0, 180); }
        else if (v.field == 5) { v.lonFrac = _clamp(v.lonFrac + delta, 0, 9999); }
        WatchUi.requestUpdate();
    }

    private function _clamp(val as Number, mn as Number, mx as Number) as Number {
        if (val < mn) { return mn; }
        if (val > mx) { return mx; }
        return val;
    }

    private function _save() as Void {
        var v   = mView;
        var lat = v.latSign.toDouble() * (v.latDeg.toDouble() + v.latFrac.toDouble() / 10000.0d);
        var lon = v.lonSign.toDouble() * (v.lonDeg.toDouble() + v.lonFrac.toDouble() / 10000.0d);
        NavManager.add(lat, lon);
        // pop WaypointEdit + WaypointMenu + NavMenu → main
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
