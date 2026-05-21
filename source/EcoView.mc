import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

class EcoView extends WatchUi.View {

    private var mTimer        as Timer.Timer? = null;
    private var mMinTick      as Number       = 0;
    var mBrightMode           as Boolean      = false;
    private var mBrightRemain as Number       = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {}

    function onShow() as Void {
        mMinTick = 59; // первый тик сразу обновит экран
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

    function activateBrightMode() as Void {
        mBrightMode   = true;
        mBrightRemain = 15;
        if (System has :setBacklight) { System.setBacklight(true); }
    }

    function deactivateBrightMode() as Void {
        mBrightMode   = false;
        mBrightRemain = 0;
    }

    function onTick() as Void {
        var app = Application.getApp() as TactixApp;
        app.checkAlarms();
        app.checkTimers();

        if (mBrightMode) {
            if (System has :setBacklight) { System.setBacklight(true); }
            mBrightRemain--;
            if (mBrightRemain <= 0) {
                mBrightMode = false;
            }
        }

        mMinTick++;
        if (mMinTick >= 60) {
            mMinTick = 0;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        var clock   = System.getClockTime();
        var timeStr = clock.hour.format("%02d") + ":" + clock.min.format("%02d");

        var now  = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var rus  = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
        var dow  = rus
            ? ["Вс","Пн","Вт","Ср","Чт","Пт","Сб"]
            : ["Su","Mo","Tu","We","Th","Fr","Sa"];
        var dateStr = (info.day as Number).format("%02d") + "-"
                    + (info.month as Number).format("%02d") + "-"
                    + dow[(info.day_of_week as Number) - 1];

        var timeFont = Graphics.FONT_NUMBER_HOT;
        var subFont  = Graphics.FONT_LARGE;
        var dateFont = Graphics.FONT_MEDIUM;

        var timeH = Graphics.getFontHeight(timeFont);
        var subH  = Graphics.getFontHeight(subFont);
        var dateH = Graphics.getFontHeight(dateFont);

        var app = Application.getApp() as TactixApp;
        var nearestTimer = app.getNearestTimerRemainingMs();
        var nearestAlarm = app.getNearestAlarmTime();

        // Время всегда по центру экрана
        var timeCy = h / 2;

        // Строки выше времени рисуем снизу вверх
        var aboveY = timeCy - timeH / 2 + 10;
        if (nearestAlarm != null) {
            aboveY -= subH;
            var alarm    = nearestAlarm as Array<Number>;
            var prefix   = rus ? "Б " : "Al ";
            var alarmStr = prefix + (alarm[0] as Number).format("%02d") + ":" + (alarm[1] as Number).format("%02d");
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, aboveY, subFont, alarmStr, Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (nearestTimer >= 0) {
            aboveY -= subH;
            var totalSec = (nearestTimer / 1000).toNumber();
            var hh = totalSec / 3600;
            var mm = (totalSec % 3600) / 60;
            var timerStr = "T " + hh.format("%02d") + ":" + mm.format("%02d");
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, aboveY, subFont, timerStr, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Время — центр по вертикали
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, timeCy, timeFont, timeStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Дата — ниже времени
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, timeCy + timeH / 2 + 4, dateFont, dateStr,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}
