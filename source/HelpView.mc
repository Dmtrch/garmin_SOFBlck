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
        var src = c[:lines] as Array;
        // 5 пустых строк сверху и снизу — для возможности доскроллить
        // любую строку в безопасную центральную зону круглого экрана.
        var padded = [] as Array;
        for (var i = 0; i < 2; i++) {
            padded.add(["", ""] as Array);
        }
        for (var j = 0; j < src.size(); j++) {
            padded.add(src[j]);
        }
        for (var k = 0; k < 2; k++) {
            padded.add(["", ""] as Array);
        }
        mLines = padded;
        scrollIdx = 0;
    }

    function maxVisible(dc as Graphics.Dc) as Number {
        var h        = dc.getHeight();
        var titleH   = Graphics.getFontHeight(Graphics.FONT_TINY);
        var rowH     = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var avail    = h - titleH - 16;
        var n        = avail / rowH;
        if (n < 1) { n = 1; }
        return n;
    }

    // Строит «render-строки» — каждая = одна визуальная строка экрана.
    // Тип каждой записи: Dictionary {
    //   :type => :pair | :left | :right | :blank,
    //   :key, :action  — для :pair
    //   :text          — для :left / :right
    // }
    // Если key+action не помещаются в availW — пара разбивается на :left + :right.
    private function _buildRender(dc as Graphics.Dc, availW as Number) as Array {
        var font   = Graphics.FONT_XTINY;
        var minGap = dc.getTextWidthInPixels("  ", font);
        var out    = [] as Array;

        for (var i = 0; i < mLines.size(); i++) {
            var row    = mLines[i] as Array;
            var key    = row[0] as String;
            var action = row[1] as String;

            if (key.equals("") && action.equals("")) {
                out.add({ :type => :blank } as Dictionary);
                continue;
            }

            var keyW = dc.getTextWidthInPixels(key,    font);
            var actW = dc.getTextWidthInPixels(action, font);

            if (keyW + minGap + actW <= availW) {
                out.add({ :type => :pair, :key => key, :action => action } as Dictionary);
            } else {
                out.add({ :type => :left,  :text => key }    as Dictionary);
                out.add({ :type => :right, :text => action } as Dictionary);
            }
        }
        return out;
    }

    function clampScroll(visible as Number, total as Number) as Void {
        var max = total - visible;
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
        dc.drawText(w / 2, 16, Graphics.FONT_TINY, mTitle,
                    Graphics.TEXT_JUSTIFY_CENTER);

        var titleH = Graphics.getFontHeight(Graphics.FONT_TINY);
        var rowH   = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var topY   = 6 + titleH + 4;

        // Боковой отступ = ширина 3 символов "M" в FONT_XTINY.
        var margin = dc.getTextWidthInPixels("MMM", Graphics.FONT_XTINY);
        var availW = w - margin * 2;

        var render  = _buildRender(dc, availW);
        var visible = maxVisible(dc);
        clampScroll(visible, render.size());

        var end = scrollIdx + visible;
        if (end > render.size()) { end = render.size(); }

        var keyCol = Graphics.COLOR_LT_GRAY;
        var actCol = Graphics.COLOR_WHITE;

        for (var i = scrollIdx; i < end; i++) {
            var item = render[i] as Dictionary;
            var type = item[:type] as Symbol;
            var rowY = topY + (i - scrollIdx) * rowH;

            if (type == :blank) { continue; }

            if (type == :pair) {
                dc.setColor(keyCol, Graphics.COLOR_TRANSPARENT);
                dc.drawText(margin, rowY, Graphics.FONT_XTINY,
                            item[:key] as String,
                            Graphics.TEXT_JUSTIFY_LEFT);
                dc.setColor(actCol, Graphics.COLOR_TRANSPARENT);
                dc.drawText(w - margin, rowY, Graphics.FONT_XTINY,
                            item[:action] as String,
                            Graphics.TEXT_JUSTIFY_RIGHT);
            } else if (type == :left) {
                dc.setColor(keyCol, Graphics.COLOR_TRANSPARENT);
                dc.drawText(margin, rowY, Graphics.FONT_XTINY,
                            item[:text] as String,
                            Graphics.TEXT_JUSTIFY_LEFT);
            } else if (type == :right) {
                dc.setColor(actCol, Graphics.COLOR_TRANSPARENT);
                dc.drawText(w - margin, rowY, Graphics.FONT_XTINY,
                            item[:text] as String,
                            Graphics.TEXT_JUSTIFY_RIGHT);
            }
        }

        // Индикаторы прокрутки
        if (scrollIdx > 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, topY - 2, Graphics.FONT_XTINY, "^",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (end < render.size()) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, topY + visible * rowH - 4, Graphics.FONT_XTINY, "v",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }

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
