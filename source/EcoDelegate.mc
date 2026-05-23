import Toybox.Lang;
import Toybox.WatchUi;

class EcoDelegate extends NoTouchDelegate {

    private var mView as EcoView;

    function initialize(view as EcoView) {
        NoTouchDelegate.initialize();
        mView = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_LIGHT) {
            if (mView.mBrightMode) {
                mView.deactivateBrightMode();
            } else {
                mView.activateBrightMode();
            }
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        WatchUi.pushView(new TactixView(), new TactixDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onMenu() as Boolean {
        pushHelp(:eco);
        return true;
    }
}
