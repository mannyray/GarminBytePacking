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
        if(1==1){
            return true;
        }

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
        var approach = 3;
        if(approach != 3){
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
        else{
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
        return true;
    }
}