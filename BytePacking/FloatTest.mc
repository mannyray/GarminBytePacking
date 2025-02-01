using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;

module BytePacking{
   
   /*
   Test case creation assisted with
    https://baseconvert.com/ieee-754-floating-point
   */

   //TODO basic test with byte array being explicitly defined
    var expectedArray = new [4]b;
    function testTwoWayASingleFloat(float as Toybox.Lang.Float){
        var computedArray = BytePacking.Float.floatToByteArray(float);
        var decoded = computedArray.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
        
        expectedArray.encodeNumber(float,Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
        assertEquivalencyBetweenByteArraysFloat(expectedArray,computedArray);


        Test.assertEqual(float,decoded);
        //expectedArray.encodeNumber(float,Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
        //assertEquivalencyBetweenByteArrays(expectedArray,computedArray);

        //var computedFloat = BytePacking.Float.byteArrayToFloat(computedArray);
        //Test.assertEqualMessage(input, computedFloat, "Expected " + input + ", but got " +computedFloat);
        //Exception: ASSERTION FAILED: [0x4b,0x80,0x0,0x4e,] versus [0x4b,0x80,0x0,0x0,]
    }

    function computeFloat(sign as Toybox.Lang.Number, exponent as Toybox.Lang.Number, mantissa as Toybox.Lang.Number){
        var biasedExponent = exponent - 127;
        var fraction = 1f + (mantissa.toFloat()/(Math.pow(2,23)).toFloat());
        return Math.pow(-1,sign).toFloat() * (Math.pow(2,biasedExponent)) * fraction;
    }

    (:test)
    function FloatTest_basicTest2(logger as Toybox.Test.Logger) as Boolean {
        var numsToTest = [0f, 100f, 16777372f, 1239.14123f, 1.1754944e-38,0.28246f,0.14123f, 0.123412356f, 0.1f, ];//0.14123f,
        for(var i=0; i<numsToTest.size(); i++){
            System.println("Testing "+numsToTest[i]);
            testTwoWayASingleFloat(numsToTest[i]);
        }
        return true;
    }


    (:test)
    function FloatTest_basicTest(logger as Toybox.Test.Logger) as Boolean {
        System.println(" TEST TEST "  + (0xFF));


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

        var maxSignedInteger = 2147483647l; //32 bit max that is
        var arr = [0x3f,0x80,0x00,0x01]b;//3F800001
        var floatEquivalent;
        var startingNumber = 1065353216l;
        var originalPercentage = startingNumber.toDouble()/maxSignedInteger.toDouble();
        var startTime = System.getTimer();
        var approach = 4;
        if(approach == 1 or approach == 2){
            for(var i=startingNumber; i<maxSignedInteger; i+=1){
                var currentPercentage = i.toDouble()/maxSignedInteger.toDouble();
                if((currentPercentage - originalPercentage)>0.00001){
                    System.println( "percentage " + (currentPercentage - originalPercentage) );
                    System.println( "millisecond time "+(System.getTimer() - startTime) );
                    return true;
                }
                if(approach == 1){
                    arr = BytePacking.Long.longToByteArray(i);
                    floatEquivalent  = arr.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 4, :endianness=>Lang.ENDIAN_BIG});
                    //System.println(floatEquivalent);
                }
                else if(approach == 2){
                    var carryOver = 1;
                    if(arr[3]==255){
                        for(var k=3; k >=0; k--){
                            if(arr[k] == 255 && carryOver == 1){
                                arr[k] = 0;
                                if(k == 0){
                                    //EXIT - should be a global break
                                    break;
                                }
                                // still hold carry over for the next lower k
                            }
                            else if(carryOver == 1){
                                arr[k]+=1;
                                break;
                            }
                        }
                    }else{
                        arr[3]+=1;
                    }
                    floatEquivalent  = arr.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG}); 
                    //System.println(floatEquivalent);
                }
                
                if(floatEquivalent >= 1){
                    //System.println(floatEquivalent);
                    testTwoWayASingleFloat(floatEquivalent);
                }
            }
        }
        else if(approach == 3){
            var counter = 0;
            var signs = [0,1];
            for( var signIndex=0; signIndex<signs.size(); signIndex++){
                var sign = signs[signIndex];
                for(var exponent=128; exponent<255; exponent++){
                    for(var mantissa=0; mantissa<Math.pow(2,23); mantissa++){
                        floatEquivalent = computeFloat(sign, exponent, mantissa);
                        //System.println(floatEquivalent);
                        testTwoWayASingleFloat(floatEquivalent);
                        counter++;
                        var currentPercentage = counter.toDouble()/maxSignedInteger.toDouble();
                        if(currentPercentage>0.00001){
                            System.println( "percentage " + currentPercentage );
                            System.println( "millisecond time "+(System.getTimer() - startTime) );
                            return true;
                        }
                    }
                }
            }
        }
        else if(approach == 4){
            Math.srand(0);
            var counter = 0;
            var max = 10000;
            startTime = System.getTimer();
            var currentPercentageStartTime = startTime;
            var nextPercentage = 0.1;
            while(counter < max){
                counter = counter + 1;
                var number = BytePacking.Long.longToByteArray( Math.rand().toLong() ).slice(4,null).decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
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
        }
        return true;
    }

    (:test)
    function FloatTest_basicTest3(logger as Toybox.Test.Logger) as Boolean {
        var numsToTest = [523.587036f, 3.712864e-39f, -523.587036f];
        for(var i=0; i<numsToTest.size(); i++){
            System.println("Testing "+numsToTest[i]);
            testTwoWayASingleFloat(numsToTest[i]);
        }
        return true;
    }
}