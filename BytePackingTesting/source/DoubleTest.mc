using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePackingTesting{
   

    (:test)
    function basicTest2(logger as Toybox.Test.Logger) as Boolean {
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
}