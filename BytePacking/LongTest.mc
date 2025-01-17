using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePacking{
    /*
    Test cases formulated with the help of
    https://www.rapidtables.com/convert/number/decimal-to-binary.html
    and 
    https://www.rapidtables.com/convert/number/binary-to-hex.html
    */

    function byteArrayToHexArrayString(arr as Toybox.Lang.ByteArray) as String{
        var outputString = "[";
        for(var arrayIndex=0; arrayIndex<arr.size(); arrayIndex++){
            outputString = outputString + "0x" +arr[arrayIndex].format("%x") +",";
        }
        outputString = outputString + "]";
        return outputString;
    }

    function assertEquivalencyBetweenByteArrays(arr1 as Toybox.Lang.ByteArray,arr2 as Toybox.Lang.ByteArray){
        Test.assertEqual(arr1.size(),arr2.size());
        for(var i=0; i<arr1.size(); i++){
            Test.assertEqualMessage(arr1[i],arr2[i],byteArrayToHexArrayString(arr1) + " versus " + byteArrayToHexArrayString(arr2));
        }
    }

    (:test)
    function basicTest(logger as Toybox.Test.Logger) as Boolean {
        var longNumber = 100l;
        /*
            in binary notation this is 1100100
            i.e. 2^6 + 2^5 + 2^2 = 64 + 32 + 4 = 100
            (index of where the one is located to the power of two with last binary being index 0)

            the above is only 7 bits long, but a long is 64 bits so technically the long number bit version would be:
            00000000 00000000 00000000 00000000 00000000 00000000 00000000 01100100
            where each block of numbers is a byte ( 8 total ).

            The full long bit notation, in hex would be
            0x0000000000000064
            with each two hex digits representing a byte for a total of 16 hex digits
            where the last two, "0x64", representing bits "01100100"
            i.e. 0x6 = 6 = 2^2 + 2^1 = 4 + 2 = "0110" AND 0x4 = 4 = 2^2 = "0100"

            Therefore we expect the byte array output of the long to be:
            [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x64]
        */
        
        var expectedArray = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x64]b;
        var computedArray = BytePacking.Long.longToByteArray(longNumber);
        assertEquivalencyBetweenByteArrays(expectedArray,computedArray);
        

        // now see if we can get the original number back from the byte array
        var newLongNumber = BytePacking.Long.byteArrayToLong(computedArray);
        Test.assertEqual(longNumber,newLongNumber);

        return true;
    }

    (:test)
    function zeroTest(logger as Toybox.Test.Logger) as Boolean {
        var zero = 0l;
        var zeroExpectedByteArray = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b;
        var zeroComputedByteArray = BytePacking.Long.longToByteArray(zero);
        assertEquivalencyBetweenByteArrays(zeroExpectedByteArray,zeroComputedByteArray);
        var newZero = BytePacking.Long.byteArrayToLong(zeroComputedByteArray);
        Test.assertEqual(zero,newZero);

        return true;
    }

    (:test)
    function bigAbsoluteValueNumberTest(logger as Toybox.Test.Logger) as Boolean {
        var biggestNumber = 9223372036854775807l;
        var biggestNumberExpectedByteArray = [0x7f,0xff,0xff,0xff,0xff,0xff,0xff,0xff]b;
        var biggestNumberComputedByteArray = BytePacking.Long.longToByteArray(biggestNumber);
        assertEquivalencyBetweenByteArrays(biggestNumberExpectedByteArray,biggestNumberComputedByteArray);
        var newBiggestNumber = BytePacking.Long.byteArrayToLong(biggestNumberComputedByteArray);
        Test.assertEqual(biggestNumber,newBiggestNumber);

        var smallestNumber = -9223372036854775808l;
        var smallestNumberExpectedByteArray = [0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b;
        var smallestNumberComputedByteArray = BytePacking.Long.longToByteArray(smallestNumber);
        assertEquivalencyBetweenByteArrays(smallestNumberExpectedByteArray,smallestNumberComputedByteArray);
        var newSmallesttNumber = BytePacking.Long.byteArrayToLong(smallestNumberComputedByteArray);
        Test.assertEqual(smallestNumber,newSmallesttNumber);

        return true;
    }

    (:test)
    function randomNumberTest(logger as Toybox.Test.Logger) as Boolean {
        var randomNumber = 2341698761234l;
        var randomNumberExpectedArray = [0x00,0x00,0x02,0x21,0x38,0x1F,0x72,0x12];
        var randomNumberComputedArray = BytePacking.Long.longToByteArray(randomNumber);
        assertEquivalencyBetweenByteArrays(randomNumberExpectedArray,randomNumberComputedArray);
        var newRandomNumber = BytePacking.Long.byteArrayToLong(randomNumberComputedArray);
        Test.assertEqual(randomNumber,newRandomNumber);

        var randomNumberNegative = -1*randomNumber;
        var randomNumberNegativeExpectedArray = [0xFF,0xFF,0xFD, 0xDE, 0xC7, 0xE0, 0x8D, 0xEE];
        var randomNumberNegativeComputedArray =  BytePacking.Long.longToByteArray(randomNumberNegative);
        assertEquivalencyBetweenByteArrays(randomNumberNegativeExpectedArray,randomNumberNegativeComputedArray);
        var newRandomNumberNegative = BytePacking.Long.byteArrayToLong(randomNumberNegativeComputedArray);
        Test.assertEqual(randomNumberNegative,newRandomNumberNegative);
        return true;
    }
}

/*
    TODO: tests
    - TODO resolve static static see if you can chain additional methods
    - exception thrown errors
    - todo casting as a long input that is not a long?
*/