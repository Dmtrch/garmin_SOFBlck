import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class MapPickDelegate extends WatchUi.BehaviorDelegate {
    private var mView      as MapPickView;
    private var mLastDragX as Number = -1;
    private var mLastDragY as Number = -1;

    function initialize(view as MapPickView) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    // Touch ────────────────────────────────────────────────────────────────
    function onTap(ev as WatchUi.ClickEvent) as Boolean {
        return true;
    }

    function onDrag(ev as WatchUi.DragEvent) as Boolean {
        var coords = ev.getCoordinates();
        var x      = coords[0];
        var y      = coords[1];
        var type   = ev.getType();

        if (type == WatchUi.DRAG_TYPE_START || mLastDragX < 0) {
            mLastDragX = x;
            mLastDragY = y;
            return true;
        }

        var dx = x - mLastDragX;
        var dy = y - mLastDragY;
        mLastDragX = x;
        mLastDragY = y;

        var mpp    = mView.metersPerPixel();
        var cosLat = Math.cos(mView.mCenterLat * Math.PI / 180.0d);
        if (cosLat < 0.01d) { cosLat = 0.01d; }

        // палец вправо (dx>0) → карта смещается вправо → центр lon уменьшается
        // палец вниз  (dy>0) → карта смещается вниз  → центр lat увеличивается
        var dLon = (-dx * mpp) / (111000.0d * cosLat);
        var dLat = ( dy * mpp) / 111000.0d;
        mView.pan(dLat, dLon);

        // Карту перерисовываем ТОЛЬКО при отпускании пальца.
        // setMapVisibleArea на каждый drag-тик вешает симулятор
        // (десятки перечитываний тайлов в секунду).
        if (type == WatchUi.DRAG_TYPE_STOP) {
            mLastDragX = -1;
            mLastDragY = -1;
            mView.commitRedraw();
        }

        WatchUi.requestUpdate();
        return true;
    }

    function onSwipe(ev as WatchUi.SwipeEvent) as Boolean {
        return true;
    }

    // Кнопки ───────────────────────────────────────────────────────────────
    function onSelect() as Boolean {
        _save();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onNextPage() as Boolean {
        _stepControl(-1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _stepControl(1);
        return true;
    }

    private function _stepControl(sign as Number) as Void {
        if (mView.mMode == 2) {
            mView.stepZoom(sign);
        } else {
            var stepM  = mView.mRadiusM * 0.1d;
            var cosLat = Math.cos(mView.mCenterLat * Math.PI / 180.0d);
            if (cosLat < 0.01d) { cosLat = 0.01d; }
            if (mView.mMode == 0) {
                mView.pan(sign * stepM / 111000.0d, 0.0d);
            } else {
                mView.pan(0.0d, sign * stepM / (111000.0d * cosLat));
            }
            mView.commitRedraw();
        }
        WatchUi.requestUpdate();
    }

    function onMenu() as Boolean {
        mView.cycleMode();
        WatchUi.requestUpdate();
        return true;
    }

    // ──────────────────────────────────────────────────────────────────────
    private function _save() as Void {
        var rus = (System.getDeviceSettings().systemLanguage == System.LANGUAGE_RUS);
        var newIdx = NavManager.add(mView.mCenterLat, mView.mCenterLon);
        if (newIdx < 0) {
            var msg = rus ? "Максимум меток" : "Max waypoints";
            WatchUi.pushView(new _NavMsgView(msg), new _NavMsgDelegate(), WatchUi.SLIDE_UP);
            return;
        }
        // pop ×2: MapPick + WaypointMenu → открыть редактор имени → выход вернёт в NavMenu
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        pushNameEdit(newIdx);
    }
}
