using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Timer;
import Toybox.System;

class TestApp extends Application.AppBase {

    var session = null;
    var timer = new Timer.Timer();
    var counter = 0l;

    function initialize() {
        AppBase.initialize();
        session = new Session();
        timer.start( method(:onTimerTic),2000,true);

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
            if(counter == 0){
                var numbers = [523l, 8129l, 654321l, 9237l, 32l];
                var bitsRequired = [10, 13, 20, 14, 6];
                bitsRequired[2]+= 1;
                var packed = new BytePacking.BPLongPacked();
                for(var i=0; i<numbers.size(); i++){
                    packed.addData(BytePacking.BinaryDataPair.binaryDataPairWithMaxBits(numbers[i],bitsRequired[i]));
                }
                var byteArray = BytePacking.BPLong.longToByteArray(packed.getData());
                var output = BytePacking.BPDouble.byteArrayToDouble(byteArray);
                session.recordData(output);
            }
            else{
                session.stop();
            }
            counter++;
        }
    }
}