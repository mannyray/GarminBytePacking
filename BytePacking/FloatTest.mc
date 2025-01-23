using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePacking{
   
   /*
   Test case creation assisted with
    https://baseconvert.com/ieee-754-floating-point
   */

   //TODO basic test with byte array being explicitly defined

    function testTwoWayASingleFloat(float as Toybox.Lang.Float){
        var computedArray = BytePacking.Float.floatToByteArray(float);
        var expectedArray = new [4]b;
        expectedArray.encodeNumber(float,Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
        assertEquivalencyBetweenByteArrays(expectedArray,computedArray);

        //var computedFloat = BytePacking.Float.byteArrayToFloat(computedArray);
        //Test.assertEqualMessage(input, computedFloat, "Expected " + input + ", but got " +computedFloat);
    
        //Exception: ASSERTION FAILED: [0x4b,0x80,0x0,0x4e,] versus [0x4b,0x80,0x0,0x0,]

    }


    (:test)
    function FloatTest_basicTest2(logger as Toybox.Test.Logger) as Boolean {
        var numsToTest = [0f, 100f, 16777372f, 1239.14123f];//0.14123f, 0.123412356f, 0.1f, 
        for(var i=0; i<numsToTest.size(); i++){
            System.println("Testing "+numsToTest[i]);
            testTwoWayASingleFloat(numsToTest[i]);
        }
        return true;
    }


    (:test)
    function FloatTest_basicTest(logger as Toybox.Test.Logger) as Boolean {

        /*
        if(1 == 1){
            var arr = [0x4b,0x80,0x0,0x4e]b;
            var floatNum = arr.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
            System.println("The number is " + floatNum);
            var myAttempt = BytePacking.Float.floatToByteArray(floatNum);
            System.println(byteArrayToHexArrayString(myAttempt));
            return true;
        }*/

        //TODO: run through all 32 bit numbers... it should be fast
         
        var input = 100f;

        /*var maxSignedInteger = 2147483647l; //32 bit max that is
        var arr;
        var floatEquivalent;
        var startingNumber = 1065353216l;
        var originalPercentage = startingNumber.toDouble()/maxSignedInteger.toDouble();
        var startTime = System.getTimer();
        for(var i=startingNumber; i<maxSignedInteger; i+=1){
            var currentPercentage = i.toDouble()/maxSignedInteger.toDouble();
            
            if((currentPercentage - originalPercentage)>0.00001){
                System.println( currentPercentage - originalPercentage );
                System.println( System.getTimer() - startTime );
                return true;
            }
            arr = BytePacking.Long.longToByteArray(i);
            floatEquivalent  = arr.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 4, :endianness=>Lang.ENDIAN_BIG});
            if(floatEquivalent >= 1){
                //System.println(floatEquivalent);
                testTwoWayASingleFloat(floatEquivalent);
            }
        }*/
        //testTwoWayASingleFloat(input);
        return true;
    }
}