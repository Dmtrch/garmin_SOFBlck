import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

class TactixView extends WatchUi.View {

    private var mTimer as Timer.Timer?;

    private var mBackground as BitmapResource?;

    // Scale relative to reference 260px screen
    private var mScale  as Float  = 1.0f;
    private var mCx     as Float  = 130.0f;
    private var mCy     as Float  = 130.0f;

    // 7-segment font params (computed from scale)
    private var mSegW   as Number = 9;  // glyph width
    private var mSegH   as Number = 16; // glyph height
    private var mSegT   as Number = 2;  // segment thickness
    private var mSegG   as Number = 2;  // geometry gap inside glyph
    private var mSegSpc as Number = 4;  // inter-character spacing
    private var mSegCol as Number = 10; // colon/space advance

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        mBackground = WatchUi.loadResource(Rez.Drawables.background) as BitmapResource;

        var w = dc.getWidth();
        mScale = w.toFloat() / 260.0f;
        mCx    = w.toFloat() / 2.0f;
        mCy    = dc.getHeight().toFloat() / 2.0f;

        mSegW   = s(12);
        mSegH   = s(19);
        var st  = s(2); mSegT = st > 1 ? st : 1;
        var sg  = s(2); mSegG = sg > 1 ? sg : 1;
        var ssp = s(4); mSegSpc = ssp > 1 ? ssp : 2;
        mSegCol = s(10);
    }

    // Scale a reference-260 value to current screen size
    private function s(v as Number) as Number {
        return (v.toFloat() * mScale + 0.5f).toNumber();
    }

    function onUpdate(dc as Dc) as Void {
        var cx = mCx.toNumber();
        var cy = mCy.toNumber();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (mBackground != null) {
            dc.drawBitmap(0, 0, mBackground);
        }

        drawTickMarks(dc, cx, cy);
        drawDataLabels(dc, cx, cy);
        drawCenterTexts(dc, cx, cy);

        // "Tactix" — под стрелками, с белым абрисом
        drawTactixLabel(dc, cx, cy);

        drawHands(dc, cx, cy);
        drawStatusOverlay(dc, cx, cy);
        drawCenterStopwatch(dc, cx, cy);
        drawCompass(dc, cx, cy);
        drawBearing(dc, cx, cy);

        var app = Application.getApp() as TactixApp;
        if (app.gpsActive) {
            var gpsColor;
            if (app.gpsQuality == Position.QUALITY_GOOD) {
                gpsColor = Graphics.COLOR_GREEN;
            } else if (app.gpsQuality == Position.QUALITY_USABLE) {
                gpsColor = Graphics.COLOR_PURPLE;
            } else if (app.gpsQuality == Position.QUALITY_POOR) {
                gpsColor = Graphics.COLOR_ORANGE;
            } else if (app.gpsQuality == Position.QUALITY_LAST_KNOWN) {
                gpsColor = Graphics.COLOR_YELLOW;
            } else {
                gpsColor = Graphics.COLOR_RED;
            }
            dc.setColor(gpsColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_TINY, "GPS",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function drawCenterStopwatch(dc as Dc, cx as Number, cy as Number) as Void {
        var app = Application.getApp() as TactixApp;
        if (!(app.hasTimer() && app.hasStopwatch())) { return; }

        var totalSec = (app.getSwElapsedMs(app.swSelectedIdx) / 1000).toNumber();
        var hh = totalSec / 3600;
        var mm = (totalSec % 3600) / 60;
        var sc = totalSec % 60;
        var mainPart = hh.format("%02d") + ":" + mm.format("%02d") + ":";
        var secPart  = sc.format("%02d");

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);

        var mainW  = segTextWidth(mainPart);
        var savedW = mSegW; var savedH = mSegH; var savedT = mSegT;
        mSegW = s(10); mSegH = s(17);
        var secW = segTextWidth(secPart);
        mSegW = savedW; mSegH = savedH;

        var startX = cx - (mainW + secW) / 2;
        var baseY  = cy + s(26) - 10;
        mSegT = savedT + 1;
        drawSegTextAt(dc, startX, baseY, mainPart);
        mSegW = s(10); mSegH = s(17);
        drawSegTextAt(dc, startX + mainW, baseY + (savedH - mSegH) / 2, secPart);
        mSegW = savedW; mSegH = savedH; mSegT = savedT;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, baseY + savedH + 2, Graphics.FONT_XTINY, "S",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawCompass(dc as Dc, cx as Number, cy as Number) as Void {
        var app = Application.getApp() as TactixApp;

        if (app.compassError) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - s(70), Graphics.FONT_XTINY, "NO COMPASS",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        if (!app.compassActive || app.compassHeading == null) { return; }

        // Защита от "залипшего" магнитометра: если новых callback'ов не было
        // дольше 3 секунд (нормальная частота 1 Гц по enableSensorEvents),
        // heading считается устаревшим — стрелки не рисуем, показываем индикатор ожидания.
        if (System.getTimer() - app.compassHeadingMs > 3000) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - s(70), Graphics.FONT_XTINY, "MAG...",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var heading = app.compassHeading as Float;
        var northAngle = -heading;
        var southAngle = northAngle + Math.PI.toFloat();

        drawCompassArrow(dc, cx, cy, northAngle, Graphics.COLOR_DK_BLUE);
        drawCompassArrow(dc, cx, cy, southAngle, Graphics.COLOR_ORANGE);
    }

    private function drawCompassArrow(dc as Dc, cx as Number, cy as Number,
                                      angleRad as Float, color as Number) as Void {
        var rTip      = s(125);
        var len       = s(20);
        var halfWidth = s(15) / 2.0f;

        var sinA = Math.sin(angleRad).toFloat();
        var cosA = Math.cos(angleRad).toFloat();

        var tx = cx.toFloat() + rTip.toFloat() * sinA;
        var ty = cy.toFloat() - rTip.toFloat() * cosA;

        var rBase = rTip.toFloat() - len.toFloat();
        var bxC = cx.toFloat() + rBase * sinA;
        var byC = cy.toFloat() - rBase * cosA;

        var bxL = bxC - halfWidth * cosA;
        var byL = byC - halfWidth * sinA;
        var bxR = bxC + halfWidth * cosA;
        var byR = byC + halfWidth * sinA;

        dc.setAntiAlias(true);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [tx.toNumber(),  ty.toNumber()],
            [bxL.toNumber(), byL.toNumber()],
            [bxR.toNumber(), byR.toNumber()]
        ] as Array<[Number, Number]>);
    }

    private function drawBearing(dc as Dc, cx as Number, cy as Number) as Void {
        var app = Application.getApp() as TactixApp;
        if (!app.bearingActive) { return; }

        var indices = app.bearingTargetIndices;
        var count   = indices.size();
        if (count == 0) { return; }

        if (!app.bearingGpsFix) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - s(85), Graphics.FONT_XTINY, "GPS...",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Без свежего heading стрелки указывали бы географический пеленг,
        // игнорируя ориентацию часов — пользователь получил бы ложное направление.
        if (app.compassHeading == null || System.getTimer() - app.compassHeadingMs > 3000) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - s(85), Graphics.FONT_XTINY, "MAG...",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var headingOffset = app.compassHeading as Float;

        var rTip  = s(125).toFloat();
        var len   = s(20).toFloat();
        var textH = Graphics.getFontHeight(Graphics.FONT_XTINY).toFloat();
        var rText = (rTip - len - 5.0f - textH / 2.0f).toNumber();

        for (var i = 0; i < count; i++) {
            var wpIdx = indices[i] as Number;
            var color = NavManager.colorFor(wpIdx);

            var angle = (app.bearingDirectionsRad[i] as Float) - headingOffset;
            drawCompassArrow(dc, cx, cy, angle, color);

            var distM = app.bearingDistancesM[i] as Float;
            var distText = (distM < 0.0f)
                ? "--"
                : (distM < 10000.0f
                    ? distM.format("%d") + "m"
                    : (distM / 1000.0f).format("%.1f") + "km");

            var deg = (angle * 180.0f / Math.PI.toFloat()).toNumber();
            deg = ((deg % 360) + 360) % 360;

            placeTextColored(dc, cx, cy, rText, deg, distText,
                             Graphics.FONT_XTINY, color);
        }
    }

    private function placeTextColored(dc as Dc, cx as Number, cy as Number, r as Number,
                                      angleDeg as Number, text as String,
                                      font as FontDefinition, color as Number) as Void {
        var angleRad = angleDeg.toFloat() * Math.PI.toFloat() / 180.0f;
        var sinA = Math.sin(angleRad).toFloat();
        var cosA = Math.cos(angleRad).toFloat();
        var tx = cx.toFloat() + r.toFloat() * sinA;
        var ty = cy.toFloat() - r.toFloat() * cosA;

        var textW = dc.getTextWidthInPixels(text, font);
        var textH = Graphics.getFontHeight(font);
        var pad   = 2;
        var bmpW  = textW + pad * 2;
        var bmpH  = textH + pad * 2;

        var bmpRef = Graphics.createBufferedBitmap({:width => bmpW, :height => bmpH});
        if (bmpRef == null) { return; }
        var bmp = bmpRef.get() as Graphics.BufferedBitmap;
        if (bmp == null) { return; }

        var bmpDc = bmp.getDc();
        bmpDc.setColor(color, Graphics.COLOR_TRANSPARENT);
        bmpDc.drawText(pad, pad, font, text, Graphics.TEXT_JUSTIFY_LEFT);

        var rotAngle = (angleDeg > 90 && angleDeg < 270)
            ? angleRad + Math.PI.toFloat()
            : angleRad;

        var cxB = (bmpW / 2.0f).toFloat();
        var cyB = (bmpH / 2.0f).toFloat();
        var t = new Graphics.AffineTransform();
        t.translate(tx, ty);
        t.rotate(rotAngle);
        t.translate(-cxB, -cyB);

        dc.drawBitmap2(0, 0, bmp, {:transform => t});
    }

    private function drawTactixLabel(dc as Dc, cx as Number, cy as Number) as Void {
        var font   = Graphics.FONT_TINY;
        var jL     = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
        var jR     = Graphics.TEXT_JUSTIFY_LEFT  | Graphics.TEXT_JUSTIFY_VCENTER;
        var xL     = cx - s(20);
        var xR     = cx + s(20);
        // Серый абрис — 8 смещений по ±1px
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) { continue; }
                dc.drawText(xL + dx, cy + dy, font, "SOF", jL);
                dc.drawText(xR + dx, cy + dy, font, "Blck", jR);
            }
        }
        // Основной чёрный текст
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xL, cy, font, "SOF", jL);
        dc.drawText(xR, cy, font, "Blck", jR);
    }

    private function drawHands(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setAntiAlias(true);

        var now      = System.getClockTime();
        var toRad    = Math.PI.toFloat() / 180.0f;
        var hourAngle = ((now.hour % 12).toFloat() + now.min.toFloat() / 60.0f) * 30.0f * toRad;
        var minAngle  = now.min.toFloat() * 6.0f * toRad;
        var secAngle  = now.sec.toFloat() * 6.0f * toRad;

        var hCos = Math.cos(hourAngle).toFloat();
        var hSin = Math.sin(hourAngle).toFloat();
        var mCos = Math.cos(minAngle).toFloat();
        var mSin = Math.sin(minAngle).toFloat();
        var sCos = Math.cos(secAngle).toFloat();
        var sSin = Math.sin(secAngle).toFloat();

        // Hour hand
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth((4.0f * mScale).toNumber());
        drawHandLine(dc, -4.0f, -10.5f, -4.0f, -40.0f, cx, cy, hCos, hSin);
        drawHandLine(dc, -4.0f, -40.0f,  0.0f, -45.2f, cx, cy, hCos, hSin);
        drawHandLine(dc,  4.0f, -10.5f,  4.0f, -40.0f, cx, cy, hCos, hSin);
        drawHandLine(dc,  4.0f, -40.0f,  0.0f, -45.2f, cx, cy, hCos, hSin);
        drawHandLine(dc, -4.0f, -10.5f,  0.0f,  -5.3f, cx, cy, hCos, hSin);
        drawHandLine(dc,  4.0f, -10.5f,  0.0f,  -5.3f, cx, cy, hCos, hSin);

        // Minute hand
        dc.setPenWidth((3.0f * mScale).toNumber());
        drawHandLine(dc, -3.0f,  -5.5f, -3.0f,  -66.5f, cx, cy, mCos, mSin);
        drawHandLine(dc, -3.0f, -66.5f,  0.0f,  -71.5f, cx, cy, mCos, mSin);
        drawHandLine(dc,  3.0f,  -5.5f,  3.0f,  -66.5f, cx, cy, mCos, mSin);
        drawHandLine(dc,  3.0f, -66.5f,  0.0f,  -71.5f, cx, cy, mCos, mSin);
        drawHandLine(dc, -3.0f,  -5.5f,  0.0f,   -3.8f, cx, cy, mCos, mSin);
        drawHandLine(dc,  3.0f,  -5.5f,  0.0f,   -3.8f, cx, cy, mCos, mSin);
        dc.setPenWidth(1);

        // Center pin
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (6.0f * mScale).toNumber());
        dc.setColor(0x1a1a1a, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (1.5f * mScale).toNumber());

        // Second hand
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        polyFill(dc, [[-1.2f, -70.0f], [-1.2f, -2.0f], [1.2f, -2.0f], [1.2f, -70.0f]]
            as Array<Array<Float>>, cx, cy, sCos, sSin);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        polyFill(dc, [[-1.2f, -80.0f], [-1.2f, -70.0f], [1.2f, -70.0f], [1.2f, -80.0f]]
            as Array<Array<Float>>, cx, cy, sCos, sSin);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (2.5f * mScale).toNumber());
    }

    private function drawHandLine(dc as Dc, x1 as Float, y1 as Float,
                                  x2 as Float, y2 as Float,
                                  cx as Number, cy as Number,
                                  cosA as Float, sinA as Float) as Void {
        var rx1 = (x1 * cosA - y1 * sinA) * mScale;
        var ry1 = (x1 * sinA + y1 * cosA) * mScale;
        var rx2 = (x2 * cosA - y2 * sinA) * mScale;
        var ry2 = (x2 * sinA + y2 * cosA) * mScale;
        dc.drawLine(cx + rx1.toNumber(), cy + ry1.toNumber(),
                    cx + rx2.toNumber(), cy + ry2.toNumber());
    }

    private function polyFill(dc as Dc, pts as Array<Array<Float>>,
                              cx as Number, cy as Number,
                              cosA as Float, sinA as Float) as Void {
        var n   = pts.size();
        var out = new Array<[Number, Number]>[n];
        for (var i = 0; i < n; i++) {
            var px = pts[i][0]; var py = pts[i][1];
            var rx = (px * cosA - py * sinA) * mScale;
            var ry = (px * sinA + py * cosA) * mScale;
            out[i] = [cx + rx.toNumber(), cy + ry.toNumber()] as [Number, Number];
        }
        dc.fillPolygon(out);
    }

    private function drawTickMarks(dc as Dc, cx as Number, cy as Number) as Void {
        var rOuter = s(82);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 60; i++) {
            var angleRad = i * 6.0f * Math.PI.toFloat() / 180.0f;
            var sinA = Math.sin(angleRad).toFloat();
            var cosA = Math.cos(angleRad).toFloat();

            var rInner; var width;
            if (i % 15 == 0) {
                rInner = s(68); width = s(4);
            } else if (i % 5 == 0) {
                rInner = s(73); width = s(3);
            } else {
                rInner = s(80); width = s(2);
            }

            var x1 = cx + (rOuter.toFloat() * sinA).toNumber();
            var y1 = cy - (rOuter.toFloat() * cosA).toNumber();
            var x2 = cx + (rInner.toFloat() * sinA).toNumber();
            var y2 = cy - (rInner.toFloat() * cosA).toNumber();

            dc.setPenWidth(width);
            dc.drawLine(x1, y1, x2, y2);
        }
        dc.setPenWidth(1);
    }

    private function drawDataLabels(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var font = Graphics.FONT_XTINY;
        var R    = s(119);

        var stats   = System.getSystemStats();
        var actInfo = ActivityMonitor.getInfo();

        if (stats.batteryInDays != null) {
            placeText(dc, cx, cy, R, 14, stats.batteryInDays.format("%d") + "d", font);
        }

        var hrHist = ActivityMonitor.getHeartRateHistory(1, true);
        if (hrHist != null) {
            var hrSample = hrHist.next();
            if (hrSample != null && hrSample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                placeText(dc, cx, cy, R, 45, hrSample.heartRate.format("%d"), font);
            }
        }

        var altIter = SensorHistory.getElevationHistory({:period => 1});
        if (altIter != null) {
            var s2 = altIter.next();
            if (s2 != null && s2.data != null) {
                placeText(dc, cx, cy, R, 78, s2.data.format("%d") + "m", font);
            }
        }

        placeText(dc, cx, cy, R, 108, getSunEventText(), font);

        if (Toybox has :Weather) {
            var cond = Toybox.Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) {
                placeText(dc, cx, cy, R, 132, cond.temperature.format("%d") + "°", font);
            }
        }

        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var rus  = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        var DOW = rus
            ? ["Вс","Пн","Вт","Ср","Чт","Пт","Сб"]
            : ["Su","Mo","Tu","We","Th","Fr","Sa"];
        var MON = rus
            ? ["Янв","Фев","Мар","Апр","Май","Июн","Июл","Авг","Сен","Окт","Ноя","Дек"]
            : ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

        // Icon-ring labels above the date cells
        var Ri = s(98);
        placeText(dc, cx, cy, Ri - 3, 157, rus ? "Н" : "W", font);
        placeText(dc, cx, cy, Ri - 3, 180, rus ? "Д" : "D", font);
        placeText(dc, cx, cy, Ri - 3, 203, rus ? "М" : "M", font);

        placeText(dc, cx, cy, R, 157, DOW[(info.day_of_week as Number) - 1], font);
        placeText(dc, cx, cy, R, 180, (info.day as Number).format("%d"), font);
        placeText(dc, cx, cy, R, 203, MON[(info.month as Number) - 1], font);

        var pressIter = SensorHistory.getPressureHistory({:period => 1});
        if (pressIter != null) {
            var s2 = pressIter.next();
            if (s2 != null && s2.data != null) {
                placeText(dc, cx, cy, R, 234, (s2.data / 100.0).toNumber().format("%d"), font);
            }
        }

        if (actInfo != null && actInfo.calories != null) {
            placeText(dc, cx, cy, R, 270, actInfo.calories.format("%d"), font);
        }
        if (actInfo != null && actInfo.steps != null) {
            placeText(dc, cx, cy, R, 306, actInfo.steps.format("%d"), font);
        }

        placeText(dc, cx, cy, R, 346, stats.battery.format("%d") + "%", font);
    }

    private function placeText(dc as Dc, cx as Number, cy as Number, r as Number,
                               angleDeg as Number, text as String,
                               font as FontDefinition) as Void {
        var angleRad = angleDeg.toFloat() * Math.PI.toFloat() / 180.0f;
        var sinA = Math.sin(angleRad).toFloat();
        var cosA = Math.cos(angleRad).toFloat();
        var tx = cx.toFloat() + r.toFloat() * sinA;
        var ty = cy.toFloat() - r.toFloat() * cosA;

        var textW = dc.getTextWidthInPixels(text, font);
        var textH = Graphics.getFontHeight(font);
        var pad   = 2;
        var bmpW  = textW + pad * 2;
        var bmpH  = textH + pad * 2;

        var bmpRef = Graphics.createBufferedBitmap({:width => bmpW, :height => bmpH});
        if (bmpRef == null) { return; }
        var bmp = bmpRef.get() as Graphics.BufferedBitmap;
        if (bmp == null) { return; }

        var bmpDc = bmp.getDc();
        bmpDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        bmpDc.drawText(pad, pad, font, text, Graphics.TEXT_JUSTIFY_LEFT);

        var rotAngle = (angleDeg > 90 && angleDeg < 270)
            ? angleRad + Math.PI.toFloat()
            : angleRad;

        var cxB = (bmpW / 2.0f).toFloat();
        var cyB = (bmpH / 2.0f).toFloat();
        var t = new Graphics.AffineTransform();
        t.translate(tx, ty);
        t.rotate(rotAngle);
        t.translate(-cxB, -cyB);

        dc.drawBitmap2(0, 0, bmp, {:transform => t});
    }

    private function getSunEventText() as String {
        if (!(Toybox has :Weather) || !(Toybox has :Position)) {
            return "--:--";
        }
        var posInfo = Position.getInfo();
        if (posInfo == null || posInfo.position == null) {
            return "--:--";
        }
        var loc = posInfo.position;
        var today = Time.now();
        var sunrise = Toybox.Weather.getSunrise(loc, today);
        var sunset  = Toybox.Weather.getSunset(loc, today);

        // Show the next upcoming event; after both passed, show tomorrow's sunrise
        var clock   = System.getClockTime();
        var nowMins = clock.hour * 60 + clock.min;

        var pick = null;
        if (sunrise != null) {
            var si = Gregorian.info(sunrise, Time.FORMAT_SHORT);
            if (si.hour * 60 + si.min > nowMins) { pick = sunrise; }
        }
        if (pick == null && sunset != null) {
            var si = Gregorian.info(sunset, Time.FORMAT_SHORT);
            if (si.hour * 60 + si.min > nowMins) { pick = sunset; }
        }
        if (pick == null) { pick = sunrise; } // show sunrise time as fallback

        if (pick == null) { return "--:--"; }
        var info = Gregorian.info(pick, Time.FORMAT_SHORT);
        return (info.hour as Number).format("%02d") + ":" + (info.min as Number).format("%02d");
    }

    // Alarm clock pictogram
    private function drawAlarmIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var r = s(7);
        var rb = r / 2; var rBell = rb > 1 ? rb : 1;
        dc.drawCircle(cx, cy, r);
        dc.drawArc(cx - rBell - 1, cy - r + 1, rBell, Graphics.ARC_COUNTER_CLOCKWISE, 30, 180);
        dc.drawArc(cx + rBell + 1, cy - r + 1, rBell, Graphics.ARC_COUNTER_CLOCKWISE, 0, 150);
        dc.drawLine(cx - s(3), cy + r, cx - s(5), cy + r + s(3));
        dc.drawLine(cx + s(3), cy + r, cx + s(5), cy + r + s(3));
        dc.drawLine(cx, cy, cx, cy - r + s(3));
    }

    private function segPoly(dc as Dc, ox as Number, oy as Number,
                             x1 as Number, y1 as Number, x2 as Number, y2 as Number,
                             horiz as Boolean) as Void {
        var pts;
        if (horiz) {
            var h = y2 - y1; var p = h / 2;
            pts = [[ox+x1, oy+y1+p], [ox+x1+p, oy+y1], [ox+x2-p, oy+y1],
                   [ox+x2, oy+y1+p], [ox+x2-p, oy+y2], [ox+x1+p, oy+y2]];
        } else {
            var w = x2 - x1; var p = w / 2;
            pts = [[ox+x1+p, oy+y1], [ox+x2, oy+y1+p], [ox+x2, oy+y2-p],
                   [ox+x1+p, oy+y2], [ox+x1, oy+y2-p], [ox+x1, oy+y1+p]];
        }
        dc.fillPolygon(pts);
    }

    private function drawSegChar(dc as Dc, ox as Number, oy as Number, ch as Number) as Number {
        var W=mSegW; var H=mSegH; var T=mSegT; var G=mSegG; var mid=H/2;
        var A=[G,0,W-G,T,true];     var B=[W-T,G,W,mid-G,false];
        var C=[W-T,mid+G,W,H-G,false]; var D=[G,H-T,W-G,H,true];
        var E=[0,mid+G,T,H-G,false]; var F=[0,G,T,mid-G,false];
        var Gm=[G,mid-T/2,W-G,mid+T-T/2,true];

        var masks = {48=>0x3F,49=>0x06,50=>0x5B,51=>0x4F,52=>0x66,
                     53=>0x6D,54=>0x7D,55=>0x07,56=>0x7F,57=>0x6F};

        if (ch == 45) {
            segPoly(dc, ox, oy, Gm[0], Gm[1], Gm[2], Gm[3], true);
            return W + mSegSpc;
        }
        if (ch == 58) {
            var r2t = T - 1; var r2 = r2t > 1 ? r2t : 1; var cx2 = ox + mSegCol/2;
            dc.fillCircle(cx2, oy + H/3, r2);
            dc.fillCircle(cx2, oy + 2*H/3, r2);
            return mSegCol;
        }
        if (ch == 32) { return W + mSegSpc; }

        var mask = masks[ch];
        if (mask == null) { return W + mSegSpc; }
        var segs = [A, B, C, D, E, F, Gm];
        var bits = [1, 2, 4, 8, 16, 32, 64];
        for (var i = 0; i < 7; i++) {
            if ((mask & bits[i]) != 0) {
                var sg = segs[i];
                segPoly(dc, ox, oy, sg[0], sg[1], sg[2], sg[3], sg[4] as Boolean);
            }
        }
        return W + mSegSpc;
    }

    private function segTextWidth(text as String) as Number {
        var total = 0;
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i+1).toCharArray()[0].toNumber();
            if (ch == 58 || ch == 32) { total += mSegCol; }
            else { total += mSegW + mSegSpc; }
        }
        return total;
    }

    private function drawSegText(dc as Dc, cx as Number, y as Number, text as String) as Void {
        var totalW = segTextWidth(text);
        var ox = cx - totalW / 2;
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i+1).toCharArray()[0].toNumber();
            ox += drawSegChar(dc, ox, y, ch);
        }
    }

    private function drawSegTextAt(dc as Dc, ox as Number, y as Number, text as String) as Number {
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i+1).toCharArray()[0].toNumber();
            ox += drawSegChar(dc, ox, y, ch);
        }
        return ox;
    }

    private function drawCenterTexts(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        var app = Application.getApp() as TactixApp;
        if (!app.hasTimer() && !app.hasStopwatch()) {
            drawAlarmArea(dc, cx, cy);
        }

        // When both timer & stopwatch are active, stopwatch replaces the clock
        // and is rendered ABOVE the hands by drawCenterStopwatch().
        if (app.hasTimer() && app.hasStopwatch()) {
            return;
        }

        var now = System.getClockTime();
        var mainPart = now.hour.format("%02d") + ":" + now.min.format("%02d") + ":";
        var secPart  = now.sec.format("%02d");

        var mainW  = segTextWidth(mainPart);
        var savedW = mSegW; var savedH = mSegH;
        mSegW = s(10); mSegH = s(17);
        var secW = segTextWidth(secPart);
        mSegW = savedW; mSegH = savedH;

        var startX = cx - (mainW + secW) / 2;
        var baseY  = cy + s(26);
        drawSegTextAt(dc, startX, baseY, mainPart);
        mSegW = s(10); mSegH = s(17);
        drawSegTextAt(dc, startX + mainW, baseY + (savedH - mSegH) / 2, secPart);
        mSegW = savedW; mSegH = savedH;
    }

    private function drawAlarmArea(dc as Dc, cx as Number, cy as Number) as Void {
        var app     = Application.getApp() as TactixApp;
        var nearest = AlarmManager.nearest(app.getAlarms());
        if (nearest == null) { return; }

        drawAlarmIcon(dc, cx, cy - s(49));
        var hStr   = (nearest["hour"] as Number).format("%02d");
        var mStr   = (nearest["min"]  as Number).format("%02d");
        var savedW = mSegW;
        mSegW = mSegW + 1;
        drawSegText(dc, cx, cy - s(34), hStr + ":" + mStr);
        mSegW = savedW;
    }

    private function drawStatusOverlay(dc as Dc, cx as Number, cy as Number) as Void {
        var app = Application.getApp() as TactixApp;
        if (app.hasTimer()) {
            drawTimerOverlay(dc, cx, cy, app);
        } else if (app.hasStopwatch()) {
            drawStopwatchOverlay(dc, cx, cy, app);
        }
    }

    private function drawStopwatchOverlay(dc as Dc, cx as Number, cy as Number, app as TactixApp) as Void {
        var totalMs  = app.getSwElapsedMs(app.swSelectedIdx);
        var totalSec = (totalMs / 1000).toNumber();
        var hh = totalSec / 3600;
        var mm = (totalSec % 3600) / 60;
        var sc = totalSec % 60;
        var timeStr = Lang.format("$1$:$2$:$3$",
            [hh.format("%02d"), mm.format("%02d"), sc.format("%02d")]);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(49), Graphics.FONT_SMALL, "S",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var savedW = mSegW;
        var savedT = mSegT;
        mSegW = mSegW + 1;
        mSegT = mSegT + 1;
        drawSegText(dc, cx, cy - s(34), timeStr);
        mSegW = savedW;
        mSegT = savedT;
    }

    private function drawTimerOverlay(dc as Dc, cx as Number, cy as Number, app as TactixApp) as Void {
        var ms = app.getTimerRemainingMs();
        var totalSec = (ms / 1000).toNumber();
        var hh = totalSec / 3600;
        var mm = (totalSec % 3600) / 60;
        var sc = totalSec % 60;
        var timeStr = Lang.format("$1$:$2$:$3$",
            [hh.format("%02d"), mm.format("%02d"), sc.format("%02d")]);

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(49), Graphics.FONT_SMALL, "T",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var savedW = mSegW;
        var savedT = mSegT;
        mSegW = mSegW + 1;
        mSegT = mSegT + 1;
        drawSegText(dc, cx, cy - s(34), timeStr);
        mSegW = savedW;
        mSegT = savedT;
    }

    function onShow() as Void {
        if (mTimer == null) {
            mTimer = new Timer.Timer();
        }
        mTimer.start(method(:onTick), 1000, true);
        if (System has :setBacklight) { System.setBacklight(true); }
    }

    function onHide() as Void {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
    }

    function onTick() as Void {
        (Application.getApp() as TactixApp).checkAlarms();
        if (System has :setBacklight) { System.setBacklight(true); }
        WatchUi.requestUpdate();
    }
}
