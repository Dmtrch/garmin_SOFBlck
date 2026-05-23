import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function pushHelp(screenId as Symbol) as Void {
    var view = new HelpView(screenId);
    WatchUi.pushView(view, new HelpDelegate(view), WatchUi.SLIDE_UP);
}

class HelpView extends WatchUi.View {

    var scrollIdx as Number = 0;
    var screenId  as Symbol;
    private var mTitle as String  = "";
    private var mLines as Array   = [] as Array;

    function initialize(id as Symbol) {
        View.initialize();
        screenId = id;
    }

    function onShow() as Void {
        var c = HelpContent.get(screenId);
        mTitle = c[:title] as String;
        mLines = c[:lines] as Array;
        scrollIdx = 0;
    }

    function maxVisible(dc as Graphics.Dc) as Number {
        var h        = dc.getHeight();
        var titleH   = Graphics.getFontHeight(Graphics.FONT_TINY);
        var hintH    = Graphics.getFontHeight(Graphics.FONT_XTINY);
        var rowH     = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var avail    = h - titleH - hintH - 16;
        var n        = avail / rowH;
        if (n < 1) { n = 1; }
        return n;
    }

    function clampScroll(visible as Number) as Void {
        var max = mLines.size() - visible;
        if (max < 0) { max = 0; }
        if (scrollIdx > max) { scrollIdx = max; }
        if (scrollIdx < 0)   { scrollIdx = 0; }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        // Заголовок
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 6, Graphics.FONT_TINY, mTitle,
                    Graphics.TEXT_JUSTIFY_CENTER);

        var titleH = Graphics.getFontHeight(Graphics.FONT_TINY);
        var rowH   = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var topY   = 6 + titleH + 4;

        var visible = maxVisible(dc);
        clampScroll(visible);

        var end = scrollIdx + visible;
        if (end > mLines.size()) { end = mLines.size(); }

        for (var i = scrollIdx; i < end; i++) {
            var row    = mLines[i] as Array;
            var key    = row[0] as String;
            var action = row[1] as String;
            var rowY   = topY + (i - scrollIdx) * rowH;

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(8, rowY, Graphics.FONT_XTINY, key,
                        Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w - 8, rowY, Graphics.FONT_XTINY, action,
                        Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Индикаторы прокрутки
        if (scrollIdx > 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, topY - 2, Graphics.FONT_XTINY, "^",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (end < mLines.size()) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, topY + visible * rowH - 4, Graphics.FONT_XTINY, "v",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Подсказка
        var rus  = HelpContent.isRus();
        var hint = rus ? "^v скролл  <- выход" : "^v scroll  <- exit";
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - 18, Graphics.FONT_XTINY, hint,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class HelpDelegate extends NoTouchDelegate {
    private var mView as HelpView;

    function initialize(view as HelpView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {
        if (mView.scrollIdx > 0) {
            mView.scrollIdx--;
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onNextPage() as Boolean {
        mView.scrollIdx++;
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onSelect() as Boolean {
        return true;
    }
}
