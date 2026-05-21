import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class TimerView extends WatchUi.View {

    private var mTimer as Timer.Timer? = null;

    var mSetupMode  as Boolean = false;
    var mSetupField as Number  = 0;
    var mSetH       as Number  = 0;
    var mSetM       as Number  = 5;
    var mSetS       as Number  = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        mSetupMode = false;
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

    function enterSetup() as Void {
        mSetupMode  = true;
        mSetupField = 0;
        var app = Application.getApp() as TactixApp;
        var dur = app.tmDurationMs[app.tmSelectedIdx] as Number;
        if (dur > 0) {
            var totalSec = dur / 1000;
            mSetH = totalSec / 3600;
            mSetM = (totalSec % 3600) / 60;
            mSetS = totalSec % 60;
        } else {
            mSetH = 0;
            mSetM = 5;
            mSetS = 0;
        }
    }

    function getSetupDurationMs() as Number {
        return ((mSetH * 3600) + (mSetM * 60) + mSetS) * 1000;
    }

    function gotoNextField() as Boolean {
        if (mSetupField < 2) { mSetupField += 1; return true; }
        return false;
    }

    function gotoPrevField() as Boolean {
        if (mSetupField > 0) { mSetupField -= 1; return true; }
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

    private function drawTimerIcon(dc as Dc, x as Number, y as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - r, y - r - 2, r * 2 + 1, 3);
        dc.fillRectangle(x - r, y + r,     r * 2 + 1, 3);
        dc.drawLine(x - r, y - r, x, y);
        dc.drawLine(x + r, y - r, x, y);
        dc.fillPolygon([[x, y], [x - r, y + r], [x + r, y + r]] as Array<[Number, Number]>);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (mSetupMode) {
            drawSetup(dc);
        } else {
            drawList(dc);
        }
    }

    private function drawList(dc as Dc) as Void {
        var app = Application.getApp() as TactixApp;
        var w   = dc.getWidth();
        var h   = dc.getHeight();

        var iconR    = h / 12;
        var iconX    = iconR + 6;
        var iconY    = h / 2;
        drawTimerIcon(dc, iconX, iconY, iconR);

        var listLeft = iconR * 2 + 14 - 20;
        if (listLeft < 0) { listLeft = 0; }
        var cx       = listLeft + (w - listLeft) / 2;

        var lineH  = Graphics.getFontHeight(Graphics.FONT_SMALL);
        var startY = h / 2 - (lineH * 5) / 2;

        for (var i = 0; i < 5; i++) {
            var y        = startY + i * lineH;
            var selected = (i == app.tmSelectedIdx);
            var running  = app.tmRunning[i] as Boolean;
            var expired  = app.tmExpired[i] as Boolean;
            var remain   = app.getTimerRemainingMsAt(i);
            var hasDur   = (app.tmDurationMs[i] as Number) > 0;

            if (selected) {
                dc.setColor(0x330000, 0x330000);
                dc.fillRectangle(listLeft, y - 2, w - listLeft, lineH + 4);
            }

            var color;
            if (expired) {
                color = Graphics.COLOR_RED;
            } else if (selected) {
                color = Graphics.COLOR_YELLOW;
            } else if (running || hasDur) {
                color = Graphics.COLOR_WHITE;
            } else {
                color = Graphics.COLOR_DK_GRAY;
            }
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);

            var totalSec = (remain / 1000).toNumber();
            var hh  = totalSec / 3600;
            var mm  = (totalSec % 3600) / 60;
            var ss  = totalSec % 60;
            var timeStr = hasDur || running || expired
                ? Lang.format("$1$:$2$:$3$", [hh.format("%02d"), mm.format("%02d"), ss.format("%02d")])
                : "--:--:--";
            var status = expired ? " !" : (running ? " >" : (hasDur ? " ||" : ""));
            dc.drawText(cx, y, Graphics.FONT_SMALL,
                        Lang.format("$1$. $2$$3$", [(i + 1).format("%d"), timeStr, status]),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

    }

    private function drawSetup(dc as Dc) as Void {
        var app = Application.getApp() as TactixApp;
        var cx  = dc.getWidth() / 2;
        var cy  = dc.getHeight() / 2;

        var hStr = mSetH.format("%02d");
        var mStr = mSetM.format("%02d");
        var sStr = mSetS.format("%02d");

        var font = Graphics.FONT_NUMBER_MEDIUM;
        var sepW = dc.getTextWidthInPixels(":", font);
        var numW = dc.getTextWidthInPixels("00", font);

        var totalW = numW * 3 + sepW * 2;
        var x = cx - totalW / 2;
        var y = cy;

        var fields = [hStr, mStr, sStr] as Array<String>;
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
        dc.drawText(cx, cy - 60, Graphics.FONT_XTINY,
                    Lang.format("Таймер $1$", [(app.tmSelectedIdx + 1).format("%d")]),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    }
}
