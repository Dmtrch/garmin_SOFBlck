import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class StopwatchView extends WatchUi.View {

    private var mTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        if (mTimer == null) {
            mTimer = new Timer.Timer();
        }
        mTimer.start(method(:onTick), 40, true);
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

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        var app = Application.getApp() as TactixApp;
        var elapsedMs = app.getSwElapsedMs();

        var totalSec = (elapsedMs / 1000).toNumber();
        var hh = totalSec / 3600;
        var mm = (totalSec % 3600) / 60;
        var ss = totalSec % 60;
        var cs = ((elapsedMs % 1000) / 10).toNumber();

        var timeStr = Lang.format("$1$:$2$:$3$:$4$", [
            hh.format("%02d"), mm.format("%02d"),
            ss.format("%02d"), cs.format("%02d")
        ]);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_MILD, timeStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var hintTop    = app.swRunning ? "START=stop" : "START=run";
        var hintBot1   = "DOWN=reset";
        var hintBot2   = "BACK=home";
        var lineH      = Graphics.getFontHeight(Graphics.FONT_XTINY);
        var align      = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.drawText(cx, cy - 60,           Graphics.FONT_XTINY, hintTop,  align);
        dc.drawText(cx, cy + 60,           Graphics.FONT_XTINY, hintBot1, align);
        dc.drawText(cx, cy + 60 + lineH,   Graphics.FONT_XTINY, hintBot2, align);
    }
}
