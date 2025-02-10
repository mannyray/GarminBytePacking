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
                // 0.4 percent of floats are nans https://stackoverflow.com/questions/19800415/why-does-ieee-754-reserve-so-many-nan-values
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
            Test.assert(1 == 0);//should never be reached.
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


    (:test)
    function FloatTest_testPacking(logger as Toybox.Test.Logger) as Boolean {
        
        // using https://baseconvert.com/ieee-754-floating-point
        
        var float1 = 1234.1234f; //0 10001001 00110100100001111110011
        var float2 = -12345.243687f; //1 10001100 10000001110010011111010

        var floatArr1 = BytePacking.BPFloat.floatToByteArray(float1);
        var floatArr2 = BytePacking.BPFloat.floatToByteArray(float2);

        var singleArr = floatArr1.addAll(floatArr2);
        Test.assert(BytePacking.BPDouble.byteArrayToDouble(singleArr)==3.100875655157453e+22d);
        
        return true;
    }


    (:test)
    function Introduction_Test(logger as Toybox.Test.Logger) as Boolean{
        var someLong = 123l;
        var byteArray = BytePacking.BPLong.longToByteArray(someLong);
        Test.assert(byteArray.equals([0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7B]b));
        Test.assert(BytePacking.BPLong.byteArrayToLong(byteArray) == someLong);

        var someFloat = 123.34f;
        byteArray = BytePacking.BPFloat.floatToByteArray(someFloat);
        Test.assert(byteArray.equals([0x42,0xF6,0xAE,0x14]b));
        Test.assert(BytePacking.BPFloat.byteArrayToFloat(byteArray) == someFloat);

        var someDouble = 1234578.65432d;
        byteArray = BytePacking.BPDouble.doubleToByteArray(someDouble);
        Test.assert(byteArray.equals([0x41,0x32,0xD6,0x92,0xA7,0x81,0x83,0xF9]b));
        Test.assert(BytePacking.BPDouble.byteArrayToDouble(byteArray) == someDouble);

        return true;
    }
}