using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Math;

var displayStringCounter = "";
var displayStringTime = "";
var displayStringDifference = "";

function updateCounterInView(counter as Toybox.Lang.Long, relativeTimeStamp as Toybox.Lang.Long, timeDifferenceToPrevious as Toybox.Lang.Long){
    displayStringCounter = "" + counter;
    var seconds = Math.floor(relativeTimeStamp.toDouble()/1000.0d);
    var hours = Math.floor(seconds/3600.0d).toNumber();
    var remainingSeconds = seconds.toNumber() % 3600;
    var minutes = Math.floor(remainingSeconds.toDouble()/60.0d).toNumber();
    var finalSeconds = remainingSeconds.toNumber() % 60;
    displayStringTime = hours.format("%02d")+":"+minutes.format("%02d")+":"+finalSeconds.format("%02d");
    displayStringDifference = ""+timeDifferenceToPrevious;
    WatchUi.requestUpdate();
}

class TestAppView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        
    }

    // Update the view
    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
        dc.clear();
        dc.drawText(
            dc.getWidth()/2,
            dc.getHeight()/2,
            Gfx.FONT_TINY,
            displayStringCounter,
            Gfx.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            dc.getWidth()/2,
            dc.getHeight()/2+25,
            Gfx.FONT_TINY,
            displayStringTime,
            Gfx.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            dc.getWidth()/2,
            dc.getHeight()/2+50,
            Gfx.FONT_TINY,
            displayStringDifference,
            Gfx.TEXT_JUSTIFY_CENTER
        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}