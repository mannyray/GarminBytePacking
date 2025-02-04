using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;

module BytePackingTesting{
   
   /*
   Test case creation assisted with
    https://baseconvert.com/ieee-754-floating-point
   */

    var expectedArray = new [4]b;
    function testTwoWayASingleFloat(float as Toybox.Lang.Float){
        var computedArray = BytePacking.BPFloat.floatToByteArray(float);
        var decoded = computedArray.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
        
        expectedArray.encodeNumber(float,Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
        assertEquivalencyBetweenByteArraysFloat(expectedArray,computedArray);

        Test.assertEqual(float,decoded);
        Test.assertEqual(float,BytePacking.BPFloat.byteArrayToFloat(computedArray));
    }

    (:test)
    function FloatTest_smokeTest(logger as Toybox.Test.Logger) as Boolean {
        Math.srand(0);
        var counter = 0;
        var max = 100;
        var startTime = System.getTimer();
        var currentPercentageStartTime = startTime;
        var nextPercentage = 0.1;
        while(counter < max){
            counter = counter + 1;
            var number = BytePacking.BPLong.longToByteArray( Math.rand().toLong() ).slice(4,null).decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
            //System.println("test number "+number);
            if(counter.toDouble()/max.toDouble() >= nextPercentage){
                System.println(nextPercentage*100.0 + ". Took " + (System.getTimer()-currentPercentageStartTime).toDouble()/1000d +" seconds." );
                nextPercentage+=0.1;
                currentPercentageStartTime = System.getTimer();
            }
            if(number.toString().equals("nan")){
                //TODO: what do we do here?
                //TODO: what do we do for inf?
                // 0.4 percent of are floats are nans https://stackoverflow.com/questions/19800415/why-does-ieee-754-reserve-so-many-nan-values
                // ^ which is significant for byke packing conerns
                // maybe according to https://en.wikipedia.org/wiki/IEEE_754-1985#:~:text=Positive%20and%20negative%20infinity%20are,biased%20exponent%20%3D%20all%201%20bits.
                // we restirct the left most bit of the exponent when byte packing?
                //https://forums.garmin.com/developer/connect-iq/f/discussion/338071/testing-for-nan/1777041#1777041
                //is there a gaunrateed bit location that prevents infs and nans?
                continue;
            }
            testTwoWayASingleFloat(number);
        }
        System.println("Overall, took " + (System.getTimer()-startTime).toDouble()/1000d +" seconds." );
        return true;
    }

    (:test)
    function FloatTest_nanCheck(logger as Toybox.Test.Logger) as Boolean {
        try {
            var arr = [0x7f,0xaf,0x34,0x67]b;// 0 11111111 01011110011010001100111
            BytePacking.BPFloat.byteArrayToFloat(arr);
        } catch (e instanceof Toybox.Lang.Exception) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Exponent all 1's - we don't deal with nans/infs";
            Test.assertMessage(
                acquiredErrorMessage.find(expectedErrorMessage) != null,
                "Invalid error message. Got '" +
                acquiredErrorMessage +
                "', expected: '" +
                expectedErrorMessage +
                "'"
            );
        }
        return true;
    }
}