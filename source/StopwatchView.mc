import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class StopwatchListView extends WatchUi.View {

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

    private function drawStopwatchIcon(dc as Dc, x as Number, y as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        var sw = r / 4;
        if (sw < 2) { sw = 2; }
        dc.fillRoundedRectangle(x - sw, y - r - r / 3, sw * 2, r / 3, 2);
        var br = r / 5;
        if (br < 2) { br = 2; }
        dc.fillCircle(x + r / 2, y - r - br, br);
        dc.drawLine(x, y, x + r * 2 / 3, y - r / 2);
        dc.fillCircle(x, y, 2);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var app = Application.getApp() as TactixApp;
        var w   = dc.getWidth();
        var h   = dc.getHeight();

        var iconR    = h / 12;
        var iconX    = iconR + 6;
        var iconY    = h / 2;
        drawStopwatchIcon(dc, iconX, iconY, iconR);

        var listLeft = iconR * 2 + 14 - 30;
        if (listLeft < 0) { listLeft = 0; }
        var cx       = listLeft + (w - listLeft) / 2;

        var lineH  = Graphics.getFontHeight(Graphics.FONT_SMALL);
        var startY = h / 2 - (lineH * 5) / 2;

        for (var i = 0; i < 5; i++) {
            var y         = startY + i * lineH;
            var selected  = (i == app.swSelectedIdx);
            var running   = app.swRunning[i] as Boolean;
            var elapsed   = app.getSwElapsedMs(i);

            if (selected) {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
                dc.fillRectangle(listLeft, y - 2, w - listLeft, lineH + 4);
            }

            if (selected) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else if (running || elapsed > 0) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }

            var totalSec = (elapsed / 1000).toNumber();
            var hh  = totalSec / 3600;
            var mm  = (totalSec % 3600) / 60;
            var ss  = totalSec % 60;
            var cs  = (elapsed % 1000) / 10;
            var timeStr = Lang.format("$1$:$2$:$3$.$4$", [
                hh.format("%02d"), mm.format("%02d"), ss.format("%02d"), cs.format("%02d")
            ]);

            var status = running ? " >" : (elapsed > 0 ? " ||" : "");
            dc.drawText(cx, y, Graphics.FONT_SMALL,
                        Lang.format("$1$. $2$$3$", [(i + 1).format("%d"), timeStr, status]),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

    }
}
