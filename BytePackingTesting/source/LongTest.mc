using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePackingTesting{
    /*
    Test cases formulated with the help of
    https://www.rapidtables.com/convert/number/decimal-to-binary.html
    and 
    https://www.rapidtables.com/convert/number/binary-to-hex.html
    */

    

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
        var computedArray = BytePacking.BPLong.longToByteArray(longNumber);
        assertEquivalencyBetweenByteArrays(expectedArray,computedArray);
        

        // now see if we can get the original number back from the byte array
        var newLongNumber = BytePacking.BPLong.byteArrayToLong(computedArray);
        Test.assertEqual(longNumber,newLongNumber);

        return true;
    }

    (:test)
    function zeroTest(logger as Toybox.Test.Logger) as Boolean {
        var zero = 0l;
        var zeroExpectedByteArray = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b;
        var zeroComputedByteArray = BytePacking.BPLong.longToByteArray(zero);
        assertEquivalencyBetweenByteArrays(zeroExpectedByteArray,zeroComputedByteArray);
        var newZero = BytePacking.BPLong.byteArrayToLong(zeroComputedByteArray);
        Test.assertEqual(zero,newZero);

        return true;
    }

    (:test)
    function bigAbsoluteValueNumberTest(logger as Toybox.Test.Logger) as Boolean {
        var biggestNumber = 9223372036854775807l;
        var biggestNumberExpectedByteArray = [0x7f,0xff,0xff,0xff,0xff,0xff,0xff,0xff]b;
        var biggestNumberComputedByteArray = BytePacking.BPLong.longToByteArray(biggestNumber);
        assertEquivalencyBetweenByteArrays(biggestNumberExpectedByteArray,biggestNumberComputedByteArray);
        var newBiggestNumber = BytePacking.BPLong.byteArrayToLong(biggestNumberComputedByteArray);
        Test.assertEqual(biggestNumber,newBiggestNumber);

        var smallestNumber = -9223372036854775808l;
        var smallestNumberExpectedByteArray = [0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b;
        var smallestNumberComputedByteArray = BytePacking.BPLong.longToByteArray(smallestNumber);
        assertEquivalencyBetweenByteArrays(smallestNumberExpectedByteArray,smallestNumberComputedByteArray);
        var newSmallesttNumber = BytePacking.BPLong.byteArrayToLong(smallestNumberComputedByteArray);
        Test.assertEqual(smallestNumber,newSmallesttNumber);

        return true;
    }

    (:test)
    function randomNumberTest(logger as Toybox.Test.Logger) as Boolean {
        var randomNumber = 2341698761234l;
        var randomNumberExpectedArray = [0x00,0x00,0x02,0x21,0x38,0x1F,0x72,0x12];
        var randomNumberComputedArray = BytePacking.BPLong.longToByteArray(randomNumber);
        assertEquivalencyBetweenByteArrays(randomNumberExpectedArray,randomNumberComputedArray);
        var newRandomNumber = BytePacking.BPLong.byteArrayToLong(randomNumberComputedArray);
        Test.assertEqual(randomNumber,newRandomNumber);

        var randomNumberNegative = -1*randomNumber;
        var randomNumberNegativeExpectedArray = [0xFF,0xFF,0xFD, 0xDE, 0xC7, 0xE0, 0x8D, 0xEE];
        var randomNumberNegativeComputedArray =  BytePacking.BPLong.longToByteArray(randomNumberNegative);
        assertEquivalencyBetweenByteArrays(randomNumberNegativeExpectedArray,randomNumberNegativeComputedArray);
        var newRandomNumberNegative = BytePacking.BPLong.byteArrayToLong(randomNumberNegativeComputedArray);
        Test.assertEqual(randomNumberNegative,newRandomNumberNegative);
        return true;
    }

    (:test)
    function errorTest(logger as Toybox.Test.Logger) as Boolean {
        var randomButTooShortInputArray = [0xFF,0xFF,0xFD, 0xDE, 0xC7, 0xE0, 0x8D]b;
        try {
            BytePacking.BPLong.byteArrayToLong(randomButTooShortInputArray);
        } catch (e instanceof Toybox.Lang.InvalidValueException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Byte array should be of size 8 and not: 7";
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
    function wrongInputTypeTest(logger as Toybox.Test.Logger) as Boolean {
        try {
            var notALongNumber = 100.09;
            BytePacking.BPLong.longToByteArray(notALongNumber);
        } catch (e instanceof Toybox.Lang.UnexpectedTypeException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting Toybox.Lang.Long argument type";
            Test.assertMessage(
                acquiredErrorMessage.find(expectedErrorMessage) != null,
                "Invalid error message. Got '" +
                acquiredErrorMessage +
                "', expected: '" +
                expectedErrorMessage +
                "'"
            );
        }
    
       try {
            var notALongNumber = 100;//a "Number" type
            BytePacking.BPLong.longToByteArray(notALongNumber);
        } catch (e instanceof Toybox.Lang.UnexpectedTypeException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting Toybox.Lang.Long argument type";
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
    function chainingMethods(logger as Toybox.Test.Logger) as Boolean {
        /*
        Since this class tested extends Toybox.Lang.Long then want to do a basic
        test if we can chain on Long methods to BytePacking.Long methods. Not a controversial test
        since the output of byteArrayToLong _is_ a Toybox.Lang.Long.
        */
        Test.assert(BytePacking.BPLong.byteArrayToLong(BytePacking.BPLong.longToByteArray(100l)).equals(100l));

        Test.assert(false == (100l).equals(100 as Number));
        // just as 100 Long is not the same as a 100 Number then
        // so is 100 BytePacking.Long not the same as 100 Long
        var testVar = 100 as BytePacking.BPLong;
        Test.assert(false == testVar.equals(100l));

        /*
        even though none of our methods in BytePacking.Long return 
        a BytePacking.Long type, we still experiment here since we don't
        restrict class user from defning things as:
        var testVar = 100 as BytePacking.Long;
        */
        Test.assert(200l == testVar + 100l);
        
        return true;
    }

}