import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Открыть редактор имени для метки. После выхода — pop назад
// (вызывающий уже спопил всё нужное, NameEditView остаётся последним
// и закрывается на BACK / последний START).
function pushNameEdit(wpIdx as Number) as Void {
    var view = new NameEditView(wpIdx);
    WatchUi.pushView(view, new NameEditDelegate(view), WatchUi.SLIDE_LEFT);
}

class NameEditView extends WatchUi.View {
    static const ALPHABET as String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -";
    static const NAME_LEN as Number = 8;

    var wpIdx     as Number;
    var pos       as Number = 0;             // 0..NAME_LEN-1
    var charIdx   as Array<Number>;          // длина NAME_LEN, индексы в ALPHABET

    private var mScale as Float = 1.0f;

    function initialize(idx as Number) {
        View.initialize();
        wpIdx = idx;
        charIdx = new [NAME_LEN] as Array<Number>;
        // Загрузить текущее имя метки и преобразовать в массив индексов
        var name = _loadName();
        for (var i = 0; i < NAME_LEN; i++) {
            if (i < name.length()) {
                var ch = name.substring(i, i + 1) as String;
                var idx2 = _indexOf(ch);
                charIdx[i] = (idx2 >= 0) ? idx2 : _indexOf(" ");
            } else {
                charIdx[i] = _indexOf(" ");
            }
        }
    }

    function onLayout(dc as Graphics.Dc) as Void {
        mScale = dc.getWidth().toFloat() / 260.0f;
    }

    private function s(v as Number) as Number {
        return (v.toFloat() * mScale + 0.5f).toNumber();
    }

    function cycleChar(delta as Number) as Void {
        var n = ALPHABET.length();
        charIdx[pos] = ((charIdx[pos] + delta) % n + n) % n;
    }

    function nextPos() as Boolean {
        pos++;
        if (pos >= NAME_LEN) {
            _save();
            return true; // saved
        }
        return false;
    }

    function commitAndExit() as Void {
        _save();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - s(70), Graphics.FONT_XTINY,
            rus ? "Имя метки" : "Waypoint name",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Строка имени — каждый символ отдельно, активный — жёлтый
        var font = Graphics.FONT_SMALL;
        var wCh  = dc.getTextWidthInPixels("M", font);
        var totalW = wCh * NAME_LEN;
        var x0   = cx - totalW / 2;
        for (var i = 0; i < NAME_LEN; i++) {
            var ch = ALPHABET.substring(charIdx[i], charIdx[i] + 1) as String;
            var col = (i == pos) ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x0 + i * wCh + wCh / 2, cy, font, ch,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Подсказки
        var lineH = Graphics.getFontHeight(Graphics.FONT_XTINY) + 2;
        var y0    = cy + s(35);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y0,             Graphics.FONT_XTINY,
            rus ? "UP/DOWN: символ" : "UP/DOWN: char",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH,     Graphics.FONT_XTINY,
            rus ? "START: след. позиция" : "START: next pos",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, y0 + lineH * 2, Graphics.FONT_XTINY,
            rus ? "BACK: сохранить" : "BACK: save",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _loadName() as String {
        var wps = NavManager.load();
        if (wpIdx < 0 || wpIdx >= wps.size()) { return "        "; }
        var wp = wps[wpIdx] as Dictionary;
        return (wp["name"] as String);
    }

    private function _indexOf(ch as String) as Number {
        return ALPHABET.find(ch) as Number;
    }

    private function _save() as Void {
        var s2 = "";
        for (var i = 0; i < NAME_LEN; i++) {
            s2 += ALPHABET.substring(charIdx[i], charIdx[i] + 1);
        }
        // Удаляем хвостовые пробелы
        var trimmed = s2;
        while (trimmed.length() > 0
               && trimmed.substring(trimmed.length() - 1, trimmed.length()).equals(" ")) {
            trimmed = trimmed.substring(0, trimmed.length() - 1);
        }
        if (trimmed.length() == 0) { trimmed = "WP" + (wpIdx + 1).format("%d"); }
        NavManager.rename(wpIdx, trimmed);
    }
}

class NameEditDelegate extends NoTouchDelegate {
    private var mView as NameEditView;

    function initialize(view as NameEditView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {  // UP → +1 char
        mView.cycleChar(1);
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {  // DOWN → -1 char
        mView.cycleChar(-1);
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var done = mView.nextPos();
        if (done) {
            // Дошли до конца — сохранено в _save(); pop в меню навигации.
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else {
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onBack() as Boolean {
        mView.commitAndExit();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onMenu() as Boolean {
        pushHelp(:waypointName);
        return true;
    }
}
