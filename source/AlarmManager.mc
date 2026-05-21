import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

class AlarmManager {
    static const MAX as Number = 5;
    private static const KEY as String = "v1alarms";

    static function load() as Array {
        var v = Application.Storage.getValue(KEY);
        if (v instanceof Array) {
            var arr = v as Array;
            if (arr.size() == MAX) {
                for (var i = 0; i < MAX; i++) {
                    var a = arr[i] as Dictionary;
                    if (!(a["sound"] instanceof Boolean)) { a["sound"] = true; }
                }
                return arr;
            }
        }
        return _defaults();
    }

    static function save(alarms as Array) as Void {
        Application.Storage.setValue(KEY, alarms);
    }

    // Returns the nearest enabled alarm {hour, min, vibe, sound}, or null
    static function nearest(alarms as Array) as Dictionary? {
        var clock = System.getClockTime();
        var nowMin = clock.hour * 60 + clock.min;
        var bestD = -1;
        var best = null as Dictionary?;
        for (var i = 0; i < MAX; i++) {
            var a = alarms[i] as Dictionary;
            if (!(a["enabled"] as Boolean)) { continue; }
            var am = (a["hour"] as Number) * 60 + (a["min"] as Number);
            var d = am - nowMin;
            if (d <= 0) { d += 1440; }
            if (bestD < 0 || d < bestD) { bestD = d; best = a; }
        }
        return best;
    }

    // Returns alarm to fire if current minute matches and wasn't already fired
    static function checkFire(alarms as Array, lastMin as Number) as Dictionary? {
        var clock = System.getClockTime();
        var cur = clock.hour * 60 + clock.min;
        if (cur == lastMin) { return null; }
        for (var i = 0; i < MAX; i++) {
            var a = alarms[i] as Dictionary;
            if (!(a["enabled"] as Boolean)) { continue; }
            if ((a["hour"] as Number) == clock.hour && (a["min"] as Number) == clock.min) {
                return a;
            }
        }
        return null;
    }

    static function defaultAlarm() as Dictionary {
        return {"hour" => 7, "min" => 0, "enabled" => false, "vibe" => true, "sound" => true} as Dictionary;
    }

    private static function _defaults() as Array {
        var arr = [] as Array;
        for (var i = 0; i < MAX; i++) {
            arr.add(defaultAlarm());
        }
        return arr;
    }
}
