import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function pushConfirmDelete(wpIdx as Number) as Void {
    var view = new ConfirmDeleteView(wpIdx);
    WatchUi.pushView(view, new ConfirmDeleteDelegate(view), WatchUi.SLIDE_UP);
}

class ConfirmDeleteView extends WatchUi.View {
    var wpIdx as Number;

    function initialize(idx as Number) {
        View.initialize();
        wpIdx = idx;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var wps  = NavManager.load();
        var name = (wpIdx >= 0 && wpIdx < wps.size())
            ? ((wps[wpIdx] as Dictionary)["name"] as String)
            : "?";

        var lineH = Graphics.getFontHeight(Graphics.FONT_SMALL);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - lineH, Graphics.FONT_SMALL,
            rus ? "Удалить?" : "Delete?",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_MEDIUM, name,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    }
}

class ConfirmDeleteDelegate extends NoTouchDelegate {
    private var mView as ConfirmDeleteView;

    function initialize(view as ConfirmDeleteView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onSelect() as Boolean {
        NavManager.removeAt(mView.wpIdx);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
