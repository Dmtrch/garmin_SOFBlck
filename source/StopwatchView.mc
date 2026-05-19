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
        mTimer.start(method(:onTick), 100, true);
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

        var app = Application.getApp() as TactixApp;
        var w   = dc.getWidth();
        var h   = dc.getHeight();
        var cx  = w / 2;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 10, Graphics.FONT_TINY, "СЕКУНДОМЕРЫ",
                    Graphics.TEXT_JUSTIFY_CENTER);

        var lineH  = Graphics.getFontHeight(Graphics.FONT_SMALL);
        var startY = h / 2 - (lineH * 5) / 2;

        for (var i = 0; i < 5; i++) {
            var y         = startY + i * lineH;
            var selected  = (i == app.swSelectedIdx);
            var running   = app.swRunning[i] as Boolean;
            var elapsed   = app.getSwElapsedMs(i);

            if (selected) {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
                dc.fillRectangle(0, y - 2, w, lineH + 4);
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
            var timeStr = Lang.format("$1$:$2$:$3$", [
                hh.format("%02d"), mm.format("%02d"), ss.format("%02d")
            ]);

            var status = running ? " >" : (elapsed > 0 ? " ||" : "");
            dc.drawText(cx, y, Graphics.FONT_SMALL,
                        Lang.format("$1$. $2$$3$", [(i + 1).format("%d"), timeStr, status]),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h - Graphics.getFontHeight(Graphics.FONT_XTINY) - 4,
                    Graphics.FONT_XTINY, "START=меню  BACK=выход",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}
