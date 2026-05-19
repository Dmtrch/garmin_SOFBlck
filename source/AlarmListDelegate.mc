import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class AlarmListDelegate extends WatchUi.BehaviorDelegate {
    private var mView as AlarmListView;

    function initialize(view as AlarmListView) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {
        mView.selectedIdx = (mView.selectedIdx + AlarmManager.MAX - 1) % AlarmManager.MAX;
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        mView.selectedIdx = (mView.selectedIdx + 1) % AlarmManager.MAX;
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        _pushSubMenu(mView.selectedIdx);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// ─── Per-alarm submenu ────────────────────────────────────────────────────────

function _pushSubMenu(idx as Number) as Void {
    var alarms = AlarmManager.load();
    var a      = alarms[idx] as Dictionary;
    var title  = "Будильник " + (idx + 1).format("%d");
    var menu   = new WatchUi.Menu2({:title => title});
    menu.addItem(new WatchUi.MenuItem("Изменить время", null, :editTime, null));
    menu.addItem(new WatchUi.ToggleMenuItem(
        "Включён", null, :enabled, a["enabled"] as Boolean, null));
    menu.addItem(new WatchUi.ToggleMenuItem(
        "Вибрация", null, :vibe, a["vibe"] as Boolean, null));
    menu.addItem(new WatchUi.ToggleMenuItem(
        "Звук", null, :sound, a["sound"] as Boolean, null));
    menu.addItem(new WatchUi.MenuItem("Удалить", null, :delete, null));
    WatchUi.pushView(menu, new AlarmSubMenuDelegate(idx), WatchUi.SLIDE_LEFT);
}

class AlarmSubMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mIdx as Number;

    function initialize(idx as Number) {
        Menu2InputDelegate.initialize();
        mIdx = idx;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id     = item.getId();
        var alarms = AlarmManager.load();
        var a      = alarms[mIdx] as Dictionary;

        if (id == :editTime) {
            var ev = new AlarmEditView(mIdx, a["hour"] as Number, a["min"] as Number);
            WatchUi.pushView(ev, new AlarmEditDelegate(ev), WatchUi.SLIDE_LEFT);
            return;
        }

        if (id == :delete) {
            alarms[mIdx] = AlarmManager.defaultAlarm();
            AlarmManager.save(alarms);
            (Application.getApp() as TactixApp).reloadAlarms();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }

        // Toggle items — CIQ already toggled the UI; read the new state
        var state = (item as WatchUi.ToggleMenuItem).isEnabled();
        if      (id == :enabled) { a["enabled"] = state; }
        else if (id == :vibe)    { a["vibe"]    = state; }
        else if (id == :sound)   { a["sound"]   = state; }
        alarms[mIdx] = a;
        AlarmManager.save(alarms);
        (Application.getApp() as TactixApp).reloadAlarms();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
