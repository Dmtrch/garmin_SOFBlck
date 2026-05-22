import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;

class NavManager {
    static const MAX as Number = 20;
    private static const KEY as String = "nav_wp";

    // Returns array of waypoint dicts: {name, lat, lon, t}
    static function load() as Array {
        var v = Application.Storage.getValue(KEY);
        if (v instanceof Array) { return v as Array; }
        return [] as Array;
    }

    static function save(arr as Array) as Void {
        Application.Storage.setValue(KEY, arr);
    }

    // Returns false if MAX already reached
    static function add(lat as Double, lon as Double) as Boolean {
        var arr = load();
        if (arr.size() >= MAX) { return false; }
        var name = "WP" + (arr.size() + 1).format("%d");
        arr.add({"name" => name, "lat" => lat, "lon" => lon} as Dictionary);
        save(arr);
        return true;
    }

    static function removeAt(idx as Number) as Void {
        var arr = load();
        if (idx >= 0 && idx < arr.size()) {
            arr.remove(arr[idx]);
        }
        save(arr);
    }

    // Haversine distance in metres
    static function distanceM(lat1 as Double, lon1 as Double,
                              lat2 as Double, lon2 as Double) as Float {
        var R  = 6371000.0d;
        var r1 = lat1 * Math.PI / 180.0d;
        var r2 = lat2 * Math.PI / 180.0d;
        var dl = (lat2 - lat1) * Math.PI / 180.0d;
        var dg = (lon2 - lon1) * Math.PI / 180.0d;
        var a  = Math.sin(dl / 2.0d) * Math.sin(dl / 2.0d)
               + Math.cos(r1) * Math.cos(r2)
               * Math.sin(dg / 2.0d) * Math.sin(dg / 2.0d);
        var c  = 2.0d * Math.atan2(Math.sqrt(a), Math.sqrt(1.0d - a));
        return (R * c).toFloat();
    }

    // Bearing in radians: 0 = north, clockwise
    static function bearingRad(lat1 as Double, lon1 as Double,
                               lat2 as Double, lon2 as Double) as Float {
        var r1  = lat1 * Math.PI / 180.0d;
        var r2  = lat2 * Math.PI / 180.0d;
        var dg  = (lon2 - lon1) * Math.PI / 180.0d;
        var x   = Math.sin(dg) * Math.cos(r2);
        var y   = Math.cos(r1) * Math.sin(r2)
                - Math.sin(r1) * Math.cos(r2) * Math.cos(dg);
        var brg = Math.atan2(x, y);
        if (brg < 0.0d) { brg += 2.0d * Math.PI; }
        return brg.toFloat();
    }
}
