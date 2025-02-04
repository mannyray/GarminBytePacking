import Toybox.Lang;
import Toybox.WatchUi;

class BytePackingTestingDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new BytePackingTestingMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}