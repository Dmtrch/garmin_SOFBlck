import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class TimerView extends WatchUi.View {

    private var mTimer as Timer.Timer?;

    var mSetupMode  as Boolean = false;
    var mSetupField as Number  = 0;    // 0=h, 1=m, 2=s
    var mSetH       as Number  = 0;
    var mSetM       as Number  = 5;
    var mSetS       as Number  = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        var app = Application.getApp() as TactixApp;
        mSetupMode = !app.hasTimer();
        if (mSetupMode) {
            mSetupField = 0;
            mSetH = 0;
            mSetM = 5;
            mSetS = 0;
        }
        if (mTimer == null) {
            mTimer = new Timer.Timer();
        }
        mTimer.start(method(:onTick), 1000, true);
    }

    function onHide() as Void {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function getSetupDurationMs() as Number {
        return ((mSetH * 3600) + (mSetM * 60) + mSetS) * 1000;
    }

    // Returns true if focus moved; false if already on last field
    function gotoNextField() as Boolean {
        if (mSetupField < 2) {
            mSetupField += 1;
            return true;
        }
        return false;
    }

    // Returns true if focus moved; false if already on first field
    function gotoPrevField() as Boolean {
        if (mSetupField > 0) {
            mSetupField -= 1;
            return true;
        }
        return false;
    }

    function bumpField(delta as Number) as Void {
        if (mSetupField == 0) {
            mSetH += delta;
            if (mSetH < 0)  { mSetH = 23; }
            if (mSetH > 23) { mSetH = 0; }
        } else if (mSetupField == 1) {
            mSetM += delta;
            if (mSetM < 0)  { mSetM = 59; }
            if (mSetM > 59) { mSetM = 0; }
        } else {
            mSetS += delta;
            if (mSetS < 0)  { mSetS = 59; }
            if (mSetS > 59) { mSetS = 0; }
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        if (mSetupMode) {
            drawSetup(dc, cx, cy);
        } else {
            drawCountdown(dc, cx, cy);
        }
    }

    private function drawCountdown(dc as Dc, cx as Number, cy as Number) as Void {
        var app = Application.getApp() as TactixApp;
        var ms  = app.getTimerRemainingMs();

        var totalSec = (ms / 1000).toNumber();
        var hh = totalSec / 3600;
        var mm = (totalSec % 3600) / 60;
        var ss = totalSec % 60;
        var timeStr = Lang.format("$1$:$2$:$3$", [
            hh.format("%02d"), mm.format("%02d"), ss.format("%02d")
        ]);

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_MEDIUM, timeStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var hintTop;
        var hintBot1;
        var hintBot2;
        if (app.tExpired) {
            hintTop  = "EXPIRED";
            hintBot1 = "DOWN=reset";
            hintBot2 = "BACK=home";
        } else if (app.tRunning) {
            hintTop  = "START=pause";
            hintBot1 = "DOWN=reset";
            hintBot2 = "BACK=home";
        } else {
            hintTop  = "START=run";
            hintBot1 = "DOWN=reset";
            hintBot2 = "BACK=home";
        }
        var lineH = Graphics.getFontHeight(Graphics.FONT_XTINY);
        var align = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.drawText(cx, cy - 60,         Graphics.FONT_XTINY, hintTop,  align);
        dc.drawText(cx, cy + 60,         Graphics.FONT_XTINY, hintBot1, align);
        dc.drawText(cx, cy + 60 + lineH, Graphics.FONT_XTINY, hintBot2, align);
    }

    private function drawSetup(dc as Dc, cx as Number, cy as Number) as Void {
        var hStr = mSetH.format("%02d");
        var mStr = mSetM.format("%02d");
        var sStr = mSetS.format("%02d");

        var font = Graphics.FONT_NUMBER_MEDIUM;
        var sepW = dc.getTextWidthInPixels(":", font);
        var numW = dc.getTextWidthInPixels("00", font);

        var totalW = numW * 3 + sepW * 2;
        var x = cx - totalW / 2;
        var y = cy;

        var fields = [hStr, mStr, sStr];
        for (var i = 0; i < 3; i++) {
            var color = (i == mSetupField) ? Graphics.COLOR_YELLOW : Graphics.COLOR_RED;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, fields[i],
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            x += numW;
            if (i < 2) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x, y, font, ":",
                            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                x += sepW;
            }
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var lineH = Graphics.getFontHeight(Graphics.FONT_XTINY);
        var align = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.drawText(cx, cy - 60,         Graphics.FONT_XTINY, "UP/DOWN=value", align);
        dc.drawText(cx, cy + 60,         Graphics.FONT_XTINY, "START=next",    align);
        dc.drawText(cx, cy + 60 + lineH, Graphics.FONT_XTINY, "BACK=prev",     align);
    }
}
