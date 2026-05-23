import Toybox.Lang;
import Toybox.System;

// Реестр справки по экранам.
// Формат записи: { :title => String, :lines => Array<[String key, String action]> }
class HelpContent {

    static function isRus() as Boolean {
        return System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS;
    }

    static function get(screenId as Symbol) as Dictionary {
        var rus = isRus();
        if (screenId == :main)         { return _main(rus); }
        if (screenId == :eco)          { return _eco(rus); }
        if (screenId == :stopwatch)    { return _stopwatch(rus); }
        if (screenId == :timer)        { return _timer(rus); }
        if (screenId == :alarmList)    { return _alarmList(rus); }
        if (screenId == :alarmEdit)    { return _alarmEdit(rus); }
        if (screenId == :alarmNotif)   { return _alarmNotif(rus); }
        if (screenId == :timerNotif)   { return _timerNotif(rus); }
        if (screenId == :waypointList) { return _waypointList(rus); }
        if (screenId == :waypointEdit) { return _waypointEdit(rus); }
        if (screenId == :navMenu)      { return _navMenu(rus); }
        if (screenId == :waypointMenu) { return _waypointMenu(rus); }
        return _unknown(rus);
    }

    private static function _navMenu(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Меню навигации" : "Navigation menu",
            :lines => [
                [rus ? "Компас"        : "Compass",         rus ? "вкл/выкл"            : "on/off"],
                [rus ? "Уст. метку"    : "Set waypoint",    rus ? "GPS / вручную / карта/удалить" : "GPS / manual / map / delete"],
                [rus ? "Направление"   : "Bearing",         rus ? "пуск пеленга по меткам" : "start bearing"],
                [rus ? "Справка"       : "Help",            rus ? "этот экран"          : "this screen"],
                [rus ? "НАЗАД"         : "BACK",            rus ? "выход"               : "exit"]
            ] as Array
        } as Dictionary;
    }

    private static function _waypointMenu(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Установить метку" : "Set waypoint",
            :lines => [
                [rus ? "Тек. коорд."  : "Current",       rus ? "по текущему GPS"     : "by current GPS"],
                [rus ? "Вручную"      : "Manual",        rus ? "ввести широту/долготу" : "enter lat/lon"],
                [rus ? "На карте"     : "Map",           rus ? "офлайн карта часов"  : "offline watch map"],
                [rus ? "Удалить"      : "Delete",        rus ? "выбрать и удалить"   : "pick to delete"],
                [rus ? "Справка"      : "Help",          rus ? "этот экран"          : "this screen"],
                [rus ? "НАЗАД"        : "BACK",          rus ? "выход"               : "exit"]
            ] as Array
        } as Dictionary;
    }

    private static function _main(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Главный экран" : "Main screen",
            :lines => [
                [rus ? "ВВЕРХ x2"   : "UP x2",     rus ? "будильники"           : "alarms list"],
                [rus ? "ВНИЗ x2"    : "DOWN x2",   rus ? "таймер"               : "timer"],
                [rus ? "ПУСК x2"    : "START x2",  rus ? "секундомер"           : "stopwatch list"],
                [rus ? "НАЗАД"      : "BACK",      rus ? "стоп компас/пеленг"   : "stop compass/bearing"],
                [rus ? "НАЗАД x2"   : "BACK x2",   rus ? "меню навигации"       : "navigation menu"],
                [rus ? "ВВЕРХ долго": "UP hold",   rus ? "эта справка"          : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _eco(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Эко-экран" : "Eco screen",
            :lines => [
                [rus ? "СВЕТ"        : "LIGHT",    rus ? "подсветка 15с"        : "backlight 15s"],
                [rus ? "НАЗАД"       : "BACK",     rus ? "выход (главный)"      : "main screen"],
                [rus ? "ВВЕРХ долго" : "UP hold",  rus ? "эта справка"          : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _stopwatch(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Секундомер" : "Stopwatch",
            :lines => [
                [rus ? "ВВЕРХ/ВНИЗ" : "UP/DOWN",  rus ? "переключить (1-5)"    : "switch (1-5)"],
                [rus ? "ПУСК"        : "START",   rus ? "старт/пауза"          : "start/pause"],
                [rus ? "ПУСК x2"     : "START x2",rus ? "сброс"                : "reset"],
                [rus ? "НАЗАД"       : "BACK",    rus ? "выход"                : "exit"],
                [rus ? "ВВЕРХ долго" : "UP hold", rus ? "эта справка"          : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _timer(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Таймер" : "Timer",
            :lines => [
                [rus ? "ВВЕРХ (наст.)": "UP (set)",  rus ? "+1 в поле"            : "+1 in field"],
                [rus ? "ВНИЗ (наст.)" : "DOWN (set)",rus ? "-1 в поле"            : "-1 in field"],
                [rus ? "ПУСК (наст.)" : "START(set)",rus ? "следующее поле/старт" : "next field/start"],
                [rus ? "ВВЕРХ/ВНИЗ"   : "UP/DOWN",   rus ? "переключить (1-5)"    : "switch (1-5)"],
                [rus ? "ПУСК"          : "START",     rus ? "старт/пауза"          : "start/pause"],
                [rus ? "ПУСК x2"       : "START x2",  rus ? "сброс"                : "reset"],
                [rus ? "НАЗАД"         : "BACK",      rus ? "пред. поле/выход"     : "prev field/exit"],
                [rus ? "ВВЕРХ долго"   : "UP hold",   rus ? "эта справка"          : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _alarmList(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Будильники" : "Alarms",
            :lines => [
                [rus ? "ВВЕРХ/ВНИЗ" : "UP/DOWN", rus ? "выбор будильника"     : "select alarm"],
                [rus ? "ПУСК"        : "START",  rus ? "меню будильника"      : "alarm menu"],
                [rus ? "НАЗАД"       : "BACK",   rus ? "выход"                : "exit"],
                [rus ? "ВВЕРХ долго" : "UP hold",rus ? "эта справка"          : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _alarmEdit(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Настройка будильника" : "Alarm edit",
            :lines => [
                [rus ? "ВВЕРХ"       : "UP",     rus ? "+1 (час/мин)"         : "+1 (hour/min)"],
                [rus ? "ВНИЗ"        : "DOWN",   rus ? "-1 (час/мин)"         : "-1 (hour/min)"],
                [rus ? "ПУСК"        : "START",  rus ? "след. поле (час↔мин)" : "next field"],
                [rus ? "НАЗАД"       : "BACK",   rus ? "сохранить и выйти"    : "save and exit"],
                [rus ? "ВВЕРХ долго" : "UP hold",rus ? "эта справка"          : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _alarmNotif(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Сигнал будильника" : "Alarm alert",
            :lines => [
                [rus ? "ПУСК"        : "START",   rus ? "выключить сигнал" : "stop alert"],
                [rus ? "НАЗАД"       : "BACK",    rus ? "выключить сигнал" : "stop alert"],
                [rus ? "ВВЕРХ долго" : "UP hold", rus ? "эта справка"      : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _timerNotif(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Сигнал таймера" : "Timer alert",
            :lines => [
                [rus ? "ПУСК"        : "START",   rus ? "выключить и сброс" : "stop and reset"],
                [rus ? "НАЗАД"       : "BACK",    rus ? "выключить и сброс" : "stop and reset"],
                [rus ? "ВВЕРХ долго" : "UP hold", rus ? "эта справка"       : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _waypointList(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Список меток" : "Waypoint list",
            :lines => [
                [rus ? "ВВЕРХ/ВНИЗ"  : "UP/DOWN",  rus ? "прокрутка"                       : "scroll"],
                [rus ? "ПУСК"         : "START",    rus ? "выбрать / удалить"               : "toggle / delete"],
                [rus ? "НАЗАД"        : "BACK",     rus ? "если выбрано: пуск пеленга; иначе выход" : "if picked: start bearing; else exit"],
                [rus ? "ВВЕРХ долго"  : "UP hold",  rus ? "эта справка"                     : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _waypointEdit(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Ввод координат" : "Coord entry",
            :lines => [
                [rus ? "ВВЕРХ"       : "UP",     rus ? "+1 цифра (0-9 цикл)" : "+1 digit (0-9 cycle)"],
                [rus ? "ВНИЗ"        : "DOWN",   rus ? "-1 цифра (0-9 цикл)" : "-1 digit (0-9 cycle)"],
                [rus ? "ПУСК"        : "START",  rus ? "след. цифра / сохр." : "next digit / save"],
                [rus ? "НАЗАД"       : "BACK",   rus ? "выход без сохр."     : "exit no save"],
                [rus ? "ВВЕРХ долго" : "UP hold",rus ? "эта справка"         : "this help"]
            ] as Array
        } as Dictionary;
    }

    private static function _unknown(rus as Boolean) as Dictionary {
        return {
            :title => rus ? "Справка" : "Help",
            :lines => [
                [rus ? "НАЗАД" : "BACK", rus ? "выход" : "exit"]
            ] as Array
        } as Dictionary;
    }
}
