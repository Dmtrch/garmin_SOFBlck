import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

class MapPickView extends WatchUi.MapView {
    public  var mCenterLat as Double;
    public  var mCenterLon as Double;
    public  var mMode      as Number  = 0;     // 0=LAT, 1=LON, 2=ZOOM
    public  var mZoomIdx   as Number  = 1;     // индекс в ZOOM_LEVELS
    public  var mRadiusM   as Double  = 500.0d;
    private var ZOOM_LEVELS as Array<Double> = [200.0d, 500.0d, 2000.0d] as Array<Double>;

    function initialize(lat as Double, lon as Double) {
        MapView.initialize();
        mCenterLat = lat;
        mCenterLon = lon;
        setMapMode(WatchUi.MAP_MODE_BROWSE);
        _recenterMap();
    }

    public function recenter() as Void {
        _recenterMap();
    }

    public function cycleMode() as Void {
        mMode = (mMode + 1) % 3;
    }

    public function stepZoom(sign as Number) as Void {
        mZoomIdx += sign;
        if (mZoomIdx < 0)                   { mZoomIdx = 0; }
        if (mZoomIdx >= ZOOM_LEVELS.size()) { mZoomIdx = ZOOM_LEVELS.size() - 1; }
        mRadiusM = ZOOM_LEVELS[mZoomIdx];
        _recenterMap();
    }

    // Сместить центр на dLat/dLon градусов и перерисовать карту.
    public function pan(dLat as Double, dLon as Double) as Void {
        mCenterLat += dLat;
        mCenterLon += dLon;
        // clamp
        if (mCenterLat >  89.9d) { mCenterLat =  89.9d; }
        if (mCenterLat < -89.9d) { mCenterLat = -89.9d; }
        if (mCenterLon >  180.0d) { mCenterLon -= 360.0d; }
        if (mCenterLon < -180.0d) { mCenterLon += 360.0d; }
        _recenterMap();
    }

    // Метры на пиксель по горизонтали (для перевода drag-смещения в градусы).
    public function metersPerPixel() as Double {
        var w = System.getDeviceSettings().screenWidth.toDouble();
        return (mRadiusM * 2.0d) / w;
    }

    private function _recenterMap() as Void {
        var cosLat = Math.cos(mCenterLat * Math.PI / 180.0d);
        if (cosLat < 0.01d) { cosLat = 0.01d; }
        var dLat = mRadiusM / 111000.0d;
        var dLon = mRadiusM / (111000.0d * cosLat);

        var sw = new Position.Location({
            :latitude  => mCenterLat - dLat,
            :longitude => mCenterLon - dLon,
            :format    => :degrees
        });
        var ne = new Position.Location({
            :latitude  => mCenterLat + dLat,
            :longitude => mCenterLon + dLon,
            :format    => :degrees
        });
        setMapVisibleArea(sw, ne);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        MapView.onUpdate(dc); // офлайн-карты OSM с диска часов
        _drawOverlay(dc);
    }

    private function _drawOverlay(dc as Graphics.Dc) as Void {
        var w   = dc.getWidth();
        var h   = dc.getHeight();
        var cx  = w / 2;
        var cy  = h / 2;
        var k   = w / 260.0f;
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        // Курсор-крест в центре
        var len = (12 * k).toNumber();
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth((2 * k).toNumber());
        dc.drawLine(cx - len, cy, cx + len, cy);
        dc.drawLine(cx, cy - len, cx, cy + len);
        dc.setPenWidth(1);

        // Три строки: LAT / LON / ZOOM (жёлтая = активная)
        var latLabel  = (mMode == 0) ? "LAT" : "lat";
        var lonLabel  = (mMode == 1) ? "LON" : "lon";
        var latColor  = (mMode == 0) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        var lonColor  = (mMode == 1) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        var zoomColor = (mMode == 2) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;

        var zoomM    = ZOOM_LEVELS[mZoomIdx];
        var zoomText = (rus ? "zoom " : "zoom ") +
                       ((zoomM >= 1000.0d)
                           ? (zoomM / 1000.0d).format("%.0f") + " км"
                           : zoomM.format("%.0f") + " м");

        var lineH = (16 * k).toNumber();
        var yTop  = (h * 0.12).toNumber();
        _shadowText(dc, cx, yTop,             Graphics.FONT_XTINY,
                    latLabel + " " + _fmtDeg(mCenterLat, true),  latColor);
        _shadowText(dc, cx, yTop + lineH,     Graphics.FONT_XTINY,
                    lonLabel + " " + _fmtDeg(mCenterLon, false), lonColor);
        _shadowText(dc, cx, yTop + lineH * 2, Graphics.FONT_XTINY, zoomText, zoomColor);

        // Подсказка снизу
        var hint = rus ? "SELECT — сохранить" : "SELECT — save";
        var yBot = (h * 0.82).toNumber();
        _shadowText(dc, cx, yBot, Graphics.FONT_XTINY, hint, Graphics.COLOR_WHITE);
    }

    // Текст с чёрной подложкой для читаемости поверх карты.
    private function _shadowText(dc as Graphics.Dc, x as Number, y as Number,
                                 font as Graphics.FontType, text as String,
                                 color as Graphics.ColorType) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        for (var dx = -1; dx <= 1; dx += 1) {
            for (var dy = -1; dy <= 1; dy += 1) {
                if (dx != 0 || dy != 0) {
                    dc.drawText(x + dx, y + dy, font, text,
                                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            }
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _fmtDeg(deg as Double, isLat as Boolean) as String {
        var hemi;
        if (isLat) {
            hemi = (deg >= 0) ? "N" : "S";
        } else {
            hemi = (deg >= 0) ? "E" : "W";
        }
        var abs = (deg >= 0) ? deg : -deg;
        return abs.format("%.4f") + "° " + hemi;
    }
}
