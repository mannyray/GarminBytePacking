using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Timer;
import Toybox.System;

class TestApp extends Application.AppBase {

    var session = null;
    var timer = new Timer.Timer();
    var counter = 0l;
    var startTimeStamp = 0l;
    var previousTimeStamp = 0l;

    function initialize() {
        AppBase.initialize();
        session = new Session();
        counter = 0l;
        startTimeStamp = System.getTimer().toLong();
        timer.start( method(:onTimerTic),1050,true);
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
        /*
            just record one data number.
            Try getting the session up and running and once
            it is and we recorded a number we quit
        */
        if (!session.isRecording() and counter == 0){
            session.start();
        }
        else{
            var packed = new BytePacking.BPLongPacked();
            // nan/inf avoidance
            packed.addData(BytePacking.BinaryDataPair.binaryDataPairWithMaxBits(0l,2));
            // storing the counter
            packed.addData(BytePacking.BinaryDataPair.binaryDataPairWithMaxBits(counter,16));
            // storing the relative time stamp
            var currentTimeStamp = System.getTimer().toLong();
            var relativeTimeStamp = currentTimeStamp - startTimeStamp;
            if(previousTimeStamp == 0){
                // only during first call of onTimerTic will this occur
                previousTimeStamp = currentTimeStamp;
            }
            packed.addData(
                BytePacking.BinaryDataPair.binaryDataPairWithMaxBits(relativeTimeStamp,26)
            );

            var timeDifferenceToPrevious = currentTimeStamp - previousTimeStamp;
            packed.addData(
                BytePacking.BinaryDataPair.binaryDataPairWithMaxBits(timeDifferenceToPrevious,11)
            );

            var byteArray = BytePacking.BPLong.longToByteArray(packed.getData());
            var dataDoubleEquivalent = BytePacking.BPDouble.byteArrayToDouble(byteArray);
            // now that we have converted the data to a double, we save it to FIT file
            session.recordData(dataDoubleEquivalent);
            counter++;
            previousTimeStamp = currentTimeStamp;

            updateCounterInView(counter, relativeTimeStamp, timeDifferenceToPrevious);
        }
    }
}