using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Timer;

class TestApp extends Application.AppBase {

    var session = null;
    var timer = new Timer.Timer();
    var counter = 0d;

    function initialize() {
        AppBase.initialize();
        session = new Session();
        timer.start( method(:onTimerTic),1000,true);

    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        session.stop();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new TestAppView(), new TestAppDelegate() ];
    }

    function onTimerTic(){
        // just record one data number. Try getting the session up and running and once it is and we recorded a number we quit
        if (!session.isRecording() and counter == 0){
            session.start();
        }
        else{
            if(counter == 0){
                session.recordData(-3.0835862373866053e-294d);
                counter++;
            }
            else{
                session.stop();
            }
        }

    }

}