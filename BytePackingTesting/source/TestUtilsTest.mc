using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePackingTesting{

    
    (:test)
    function TestUtilsTest_byteToBinaryString_Test(logger as Toybox.Test.Logger) as Boolean {
        Test.assertEqualMessage("00000000",byteToBinaryString(0),byteToBinaryString(0));
        Test.assertEqualMessage("01100100",byteToBinaryString(100),byteToBinaryString(100));
        Test.assertEqualMessage("11111111",byteToBinaryString(255),byteToBinaryString(255));
        return true;
    }
}