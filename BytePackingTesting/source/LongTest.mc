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
    function Long_basicTest(logger as Toybox.Test.Logger) as Boolean {
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
    function Long_zeroTest(logger as Toybox.Test.Logger) as Boolean {
        var zero = 0l;
        var zeroExpectedByteArray = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b;
        var zeroComputedByteArray = BytePacking.BPLong.longToByteArray(zero);
        assertEquivalencyBetweenByteArrays(zeroExpectedByteArray,zeroComputedByteArray);
        var newZero = BytePacking.BPLong.byteArrayToLong(zeroComputedByteArray);
        Test.assertEqual(zero,newZero);

        return true;
    }

    (:test)
    function Long_bigAbsoluteValueNumberTest(logger as Toybox.Test.Logger) as Boolean {
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
    function Long_randomNumberTest(logger as Toybox.Test.Logger) as Boolean {
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
    function Long_errorTest(logger as Toybox.Test.Logger) as Boolean {
        var randomButTooShortInputArray = [0xFF,0xFF,0xFD, 0xDE, 0xC7, 0xE0, 0x8D]b;
        try {
            BytePacking.BPLong.byteArrayToLong(randomButTooShortInputArray);
            Test.assert(1 == 0);//should never be reached.
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
    function Long_wrongInputTypeTest(logger as Toybox.Test.Logger) as Boolean {
        try {
            var notALongNumber = 100.09;
            BytePacking.BPLong.longToByteArray(notALongNumber);
            Test.assert(1 == 0);//should never be reached.
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
            Test.assert(1 == 0);//should never be reached.
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
    function Long_chainingMethods(logger as Toybox.Test.Logger) as Boolean {
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


    (:test)
    function Long_BPLongPacked_test(logger as Toybox.Test.Logger) as Boolean {
        
        /*
            We have a few numbers we want to pack into a single long
        */
        var numbers = [
            523l, // 1000001011 - 10 digits
            8129l, // 1111111000001 - 13 digits
            654321l, // 10011111101111110001 - 20 digits
            9237l // 10010000010101 -  14 digits
            ];
        var bitsRequired = [10, 13, 20, 14, 8];
        /*
            pad one of the entries with zeros

            this is useful in scenarios where you have a varying data point within some range of
            say [0,255] (8 bit max range), but at times enter in data that doesn't require
            all the bits (say your data is 16 which is 5 binary digits), but for consistency and
            later on processing sake you want to make sure you always use the 8 bits which
            is why you would pad.
        */

        bitsRequired[2]+= 1;
        // we now have 58 bits

        // Let's starting packing the data into the long:
        var packed = new BytePacking.BPLongPacked();
        for(var i=0; i<numbers.size(); i++){
            packed.addData(BytePacking.BinaryDataPair.binaryDataPairWithMaxBits(numbers[i],bitsRequired[i]));
        }

        Test.assert(packed.getCurrentBitOccuputation()==58);

        /*
            Our number is
            1000001011 1111111000001 0 10011111101111110001 10010000010101 (that's the 58 up to now and the rest zeros) 000000
            or compacted 1000001011111111100000101001111110111111000110010000010101000000 which according to
            https://www.rapidtables.com/convert/number/binary-to-decimal.html
            is equivalent to -9007337107100203712

            Out of 64 bits in long, 6 bits are maining as first 58 are used
            
        */
        Test.assert(packed.getData() == -9007337107100203712l);
        
        // we now try to pack something that does not fit into the remaining 6 bits ( 64 == 7 bits) and fail
        try {
            packed.addData(new BytePacking.BinaryDataPair(64l));
            Test.assert(1 == 0);//should never be reached.
        } catch (e instanceof Toybox.Lang.InvalidValueException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "We are already storing too much";
            Test.assertMessage(
                acquiredErrorMessage.find(expectedErrorMessage) != null,
                "Invalid error message. Got '" +
                acquiredErrorMessage +
                "', expected: '" +
                expectedErrorMessage +
                "'"
            );
        }

        //However 32 fits as it is 6 bits
        packed.addData(new BytePacking.BinaryDataPair(32l));

        /*
            Our new long in bits is 
            1000001011111111100000101001111110111111000110010000010101100000
        */
        Test.assert(packed.getData() == -9007337107100203680l);
        Test.assert(packed.getCurrentBitOccuputation()==64);// no more bits left over

        /*
            we now extract the byte array of the stored long
            and verify that it is equal to what is expected
        */
        var byteArray = BytePacking.BPLong.longToByteArray(packed.getData());
        assertEquivalencyBetweenByteArrays(byteArray, [0x82,0xFF,0x82,0x9F,0xBF,0x19,0x05,0x60]b);

        /*
            Now that we have the byte array of a long which is 64 bits, we can express it as 
            a double which is also 64 bits long
        */
        Test.assert(BytePacking.BPDouble.byteArrayToDouble(byteArray)==-3.0835862373866053e-294d);


        return true;
    }

}