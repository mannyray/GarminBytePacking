using Toybox.ActivityRecording as Record;
using Toybox.FitContributor as Fit;

/*
    skeleton version of 
    https://github.com/Sennevds/garmin-squash/blob/98f6a3548b666e3f7396cdfcdd26ce1443f9520b/source/Session.mc
*/

//! Class used to record an activity
class Session {

    //! Garmin session object
    hidden var session;

    var dataField;
    var DATA_FIELD_ID=0;

    //! Constructor
    function initialize() {
        session = null;
    }

    //! Start recording a new session
    //! If the session was already recording, nothing happens
    function start(){
        if(Toybox has :ActivityRecording ) {
            if(!isRecording()) {
                session = Record.createSession({:name=>"random", :sport=>Record.SPORT_GENERIC});
                setupFields();
                session.start();
            }
        }
    }

    //! Stops the current session
    //! If the session was already stopped, nothing happens
    function stop() {
        if(isRecording()) {
            session.stop();
            session.save();
            session = null;
        }
    }

    //! Returns true if the session is recording
    function isRecording() {
        return (session != null) && session.isRecording();
    }

    hidden function setupFields() {
        dataField = session.createField("field", DATA_FIELD_ID, FitContributor.DATA_TYPE_DOUBLE, { :mesgType=>Fit.MESG_TYPE_RECORD });
    }

    function recordData(data as Toybox.Lang.Double) {
        dataField.setData(data);
        vibrate();
    }

    function vibrate() {
        if (Attention has :vibrate) {
            var vibrateData = [
                    new Attention.VibeProfile(  25, 100 ),
                  ];

            Attention.vibrate(vibrateData);
        }
    }

}