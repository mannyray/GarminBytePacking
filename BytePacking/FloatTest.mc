using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePacking{
   
   /*
   Test case creation assisted with
    https://baseconvert.com/ieee-754-floating-point
   */

    (:test)
    function FloatTest_basicTest(logger as Toybox.Test.Logger) as Boolean {
        var input = 100f;
        var computedArray = BytePacking.Float.floatToByteArray(input);
        var expectedArray = [0x42,0xc8,0x0,0x0]b;        
        assertEquivalencyBetweenByteArrays(expectedArray,computedArray);
        
        var garminComputedArray = new [4]b;
        garminComputedArray.encodeNumber(input,Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG});
        assertEquivalencyBetweenByteArrays(garminComputedArray, expectedArray);
        return true;
    }
}