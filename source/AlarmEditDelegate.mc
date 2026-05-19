import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class AlarmEditDelegate extends WatchUi.BehaviorDelegate {
    private var mView as AlarmEditView;

    function initialize(view as AlarmEditView) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onPreviousPage() as Boolean {
        if (mView.field == 0) {
            mView.hour = (mView.hour + 23) % 24;
        } else {
            mView.min = (mView.min + 59) % 60;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        if (mView.field == 0) {
            mView.hour = (mView.hour + 1) % 24;
        } else {
            mView.min = (mView.min + 1) % 60;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        mView.field = (mView.field + 1) % 2;
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        var alarms  = AlarmManager.load();
        var a       = alarms[mView.getIdx()] as Dictionary;
        a["hour"]   = mView.hour;
        a["min"]    = mView.min;
        alarms[mView.getIdx()] = a;
        AlarmManager.save(alarms);
        (Application.getApp() as TactixApp).reloadAlarms();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
