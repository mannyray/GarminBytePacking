using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePacking{
    (:test)
    function UtilTest_basic_BinaryDataPair_Test(logger as Toybox.Test.Logger) as Boolean {
        // random test case sourced from chatgpt including 0 and biggest number edge cases
        var numbers = [523l, 8129l, 349l, 2380l, 654321l, 9237l, 173l, 12981l, 4659l, 1024l, 0l, 9223372036854775807l];
        var bitsRequired = [10, 13, 9, 12, 20, 14, 8, 14, 13, 11, 0, 63];
        for(var i=0; i<numbers.size(); i++){
            var bdp = new BinaryDataPair(numbers[i]);
            Test.assertEqual(bdp.bitCount,bitsRequired[i]);
            Test.assertEqual(bdp.long,numbers[i]);
        }
        return true;
    }

    (:test)
    function UtilTest_invalidInput_BinaryDataPair_Test(logger as Toybox.Test.Logger) as Boolean {
        try {
            new BinaryDataPair(100);
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
            new BinaryDataPair(-100l);
        } catch (e instanceof Toybox.Lang.InvalidValueException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting a non negative long";
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


    class GetBitsOfDecimal_TestCase{
        var double as Double;
        var bitsRequired as Number;
        var longEquivalent as Long;
        var depth as Number;
        var binaryVersionOfDecimal as String;
        var binaryWithoutLeadingZeros as String;
        function initialize(doubleInput as Double, maxDepthCount as Number, bits as Number, long as Long, binaryVersionOfDecimalInput as String, binaryWithoutLeadingZerosInput as String){
            double = doubleInput;
            depth = maxDepthCount;
            bitsRequired = bits;
            longEquivalent = long;
            binaryVersionOfDecimal = binaryVersionOfDecimalInput;
            binaryWithoutLeadingZeros = binaryWithoutLeadingZerosInput;
        }
    }

    (:test)
    function UtilTest_basic_getBitsOfDecimal_Test(logger as Toybox.Test.Logger) as Boolean {
        /*
        Used
        https://www.rapidtables.com/convert/number/decimal-to-binary.html
        https://www.rapidtables.com/convert/number/binary-to-decimal.html
        for generating test cases
        */

        var bitCountForSign = 1;
        var bitCountForExponent = 11;
        var totalBitCount = 64;
        var maxDepthDefault = totalBitCount-bitCountForSign-bitCountForExponent;

        var testCases = [
            new GetBitsOfDecimal_TestCase(0.125d,maxDepthDefault,3,1l,".001","1"),
            // test 0 case
            new GetBitsOfDecimal_TestCase(0d,maxDepthDefault,0,0l,"_nill_","_nill_"),
            /*
                Running https://www.rapidtables.com/convert/number/decimal-to-binary.html?x=.12341465
                returns 0.0001111110011000001, but then running with the output:
                https://www.rapidtables.com/convert/number/binary-to-decimal.html?x=.0001111110011000001
                we get 0.1234149932861328125 which is not the original number.

                The issue is fundamentally precision which is the algorithm here, will continue to dig until reaching
                maximum allowed bit count. Binary can only be so precise with certain numbers.
                https://www.quora.com/Is-it-true-that-some-binary-numbers-have-infinite-digits-after-the-point-or-will-they-ever-end-for-example-decimal-0-1-to-binary

                https://www.rapidtables.com/convert/number/binary-to-decimal.html?x=.0001111110011000000110100011110110011000111001111100
                is actually 0.12341464999999995911 - real close.

            */
            new GetBitsOfDecimal_TestCase(0.12341465d,maxDepthDefault,52,555810171752060l,"0.0001111110011000000110100011110110011000111001111100","1111110011000000110100011110110011000111001111100"),
            /*
                0.1 in decimal, in binary, has inifinite number of repeating binary numbers.
                Here we test, how many binary bits do we want to extract from this infinitely repeating pattern of "0011"
            */
            new GetBitsOfDecimal_TestCase(0.1d,10,10,102l,"0.0001100110","1100110"),
            new GetBitsOfDecimal_TestCase(0.1d,20,20,104857l,"0.00011001100110011001","11001100110011001"),
            new GetBitsOfDecimal_TestCase(0.1d,0,0,0l,"0.0","0"),
        ];
        for(var i=0; i<testCases.size(); i++){
            var bdp =  getBitsOfDecimal(testCases[i].double,testCases[i].depth);
            Test.assertEqualMessage(bdp.bitCount,testCases[i].bitsRequired,
                Toybox.Lang.format(
                    "Requiring $1$ bits to store $2$ (binary version: $3$), but got $4$ bits computed.",
                    [testCases[i].bitsRequired,testCases[i].double,testCases[i].binaryVersionOfDecimal,bdp.bitCount]
                )
            );
            Test.assertEqualMessage(bdp.long,testCases[i].longEquivalent,
                Toybox.Lang.format(
                    "Long stored version of $1$ should be $3$ (or in binary $3$), but got $4$",
                    [testCases[i].double,testCases[i],testCases[i].longEquivalent,bdp.long]
                )
            );
        }
        return true;
    }

    (:test)
    function UtilTest_invalidInput_getBitsOfDecimal_Test(logger as Toybox.Test.Logger) as Boolean {
        var randomDepth = 10;
        try {
            getBitsOfDecimal(0.123f,randomDepth);//supposed to be a double and a float
        } catch (e instanceof Toybox.Lang.UnexpectedTypeException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting Toybox.Lang.Double argument type";
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
            getBitsOfDecimal(1d,randomDepth);
        } catch (e instanceof Toybox.Lang.InvalidValueException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting a Toybox.Lang.Double in the range of (0,1)";
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
            getBitsOfDecimal(-0.123d,randomDepth);
        } catch (e instanceof Toybox.Lang.InvalidValueException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting a Toybox.Lang.Double in the range of (0,1)";
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
}