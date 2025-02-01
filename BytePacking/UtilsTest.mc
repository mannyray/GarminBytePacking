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
        var bitsAfterFirstOne as Number;
        var longEquivalent as Long;
        var maxArgument as Dictionary;
        var binaryVersionOfDecimal as String;
        var binaryWithoutLeadingZeros as String;
        var truncatedValueOfBinaryInDouble as Double;
        function initialize(input as Dictionary){
            double = input[:doubleInput];
            maxArgument = input[:maxArgument];
            bitsRequired = input[:bitsRequired];
            bitsAfterFirstOne = input[:bitsAfterFirstOne];
            longEquivalent = input[:longEquivalent];
            binaryVersionOfDecimal = input[:binaryVersionOfDecimal];
            binaryWithoutLeadingZeros = input[:binaryWithoutLeadingZeros];
            truncatedValueOfBinaryInDouble = input[:truncatedValueOfBinaryInDouble];
            //TODO: new argument to test new maximumParamater
            //TODO: format input to tests as dictionary for readability
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
        var maxDepthDefaultArg = { :maximumBits => (totalBitCount-bitCountForSign-bitCountForExponent) };

        var testCases = [
            new GetBitsOfDecimal_TestCase(
                {
                    :doubleInput=>0.125d,
                    :maxArgument=>maxDepthDefaultArg,
                    :bitsRequired=>3,
                    :bitsAfterFirstOne=>1,
                    :longEquivalent=>1l,
                    :binaryVersionOfDecimal=>".001",
                    :binaryWithoutLeadingZeros=>"1",
                    :truncatedValueOfBinaryInDouble=>0.125d
                }),
            // test 0 case
            new GetBitsOfDecimal_TestCase(
                {
                    :doubleInput=>0d,
                    :maxArgument=>maxDepthDefaultArg,
                    :bitsRequired=>0,
                    :bitsAfterFirstOne=>0,
                    :longEquivalent=>0l,
                    :binaryVersionOfDecimal=>"_nill_",
                    :binaryWithoutLeadingZeros=>"_nill_",
                    :truncatedValueOfBinaryInDouble=>0d
                }),
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
            new GetBitsOfDecimal_TestCase(
                {
                    :doubleInput=>0.12341465d,
                    :maxArgument=>maxDepthDefaultArg,
                    :bitsRequired=>52,
                    :bitsAfterFirstOne=>49,
                    :longEquivalent=>555810171752060l,
                    :binaryVersionOfDecimal=>"0.0001111110011000000110100011110110011000111001111100",
                    :binaryWithoutLeadingZeros=>"1111110011000000110100011110110011000111001111100",
                    :truncatedValueOfBinaryInDouble=>0.12341464999999995911d
            }),
            /*
                0.1 in decimal, in binary, has inifinite number of repeating binary numbers.
                Here we test, how many binary bits do we want to extract from this infinitely repeating pattern of "0011"
            */
            new GetBitsOfDecimal_TestCase(
                  {
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBits=>10},
                    :bitsRequired=>10,
                    :bitsAfterFirstOne=>7,
                    :longEquivalent=>102l,
                    :binaryVersionOfDecimal=>"0.0001100110",
                    :binaryWithoutLeadingZeros=>"1100110",
                    :truncatedValueOfBinaryInDouble=>0.099609375d
            }),
            new GetBitsOfDecimal_TestCase({
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBits=>20},
                    :bitsRequired=>20,
                    :bitsAfterFirstOne=>17,
                    :longEquivalent=>104857l,
                    :binaryVersionOfDecimal=>"0.00011001100110011001",
                    :binaryWithoutLeadingZeros=>"11001100110011001",
                    :truncatedValueOfBinaryInDouble=>0.09999942779541015625d
            }),
            /*
                TODO: explanation
            */
            new GetBitsOfDecimal_TestCase({
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBitsAfterFirstOne=>7},
                    :bitsRequired=>10,
                    :bitsAfterFirstOne=>7,
                    :longEquivalent=>102l,
                    :binaryVersionOfDecimal=>"0.0001100110",
                    :binaryWithoutLeadingZeros=>"1100110",
                    :truncatedValueOfBinaryInDouble=>0.099609375d
            }),            
            new GetBitsOfDecimal_TestCase({
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBitsAfterFirstOne=>17},
                    :bitsRequired=>20,
                    :bitsAfterFirstOne=>17,
                    :longEquivalent=>104857l,
                    :binaryVersionOfDecimal=>"0.00011001100110011001",
                    :binaryWithoutLeadingZeros=>"11001100110011001",
                    :truncatedValueOfBinaryInDouble=>0.09999942779541015625d
            }), 
            new GetBitsOfDecimal_TestCase({
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBitsAfterFirstOne=>0},
                    :bitsRequired=>0,
                    :bitsAfterFirstOne=>0,
                    :longEquivalent=>0l,
                    :binaryVersionOfDecimal=>"0.0",
                    :binaryWithoutLeadingZeros=>"0",
                    :truncatedValueOfBinaryInDouble=>0d
            }),
            //TODO: test case that highlights the difference between maxbits to maxbitsafterfirstone

        ];
        for(var i=0; i<testCases.size(); i++){

            var output =  getBitsOfDecimal(testCases[i].double,testCases[i].maxArgument );
            Test.assertEqualMessage(output.totalBitCount,testCases[i].bitsRequired,
                Toybox.Lang.format(
                    "Requiring $1$ bits to store $2$ (binary version: $3$), but got $4$ bits computed.",
                    [testCases[i].bitsRequired,testCases[i].double,testCases[i].binaryVersionOfDecimal,output.totalBitCount]
                )
            );
            Test.assertEqualMessage(output.long,testCases[i].longEquivalent,
                Toybox.Lang.format(
                    "Long stored version of $1$ should be $3$ (or in binary $2$), but got $4$",//TODO: typo here?
                    [testCases[i].double,testCases[i].binaryVersionOfDecimal,testCases[i].longEquivalent,output.long]
                )
            );
            Test.assertEqualMessage(getDecimalOfBits(output),testCases[i].truncatedValueOfBinaryInDouble,
                Toybox.Lang.format(
                    "Truncated double version of $1$ should be $2$, but got $3$",
                    [testCases[i].double,testCases[i].truncatedValueOfBinaryInDouble,getDecimalOfBits(output)]
                )
            );
            Test.assertEqualMessage(output.bitCountAfterFirstOne,testCases[i].bitsAfterFirstOne,
                Toybox.Lang.format(
                    "Truncated version of $1$ should has $2$ bits after first one, but got $3$ for the binary decimal $4$",
                    [testCases[i].truncatedValueOfBinaryInDouble,testCases[i].bitsAfterFirstOne,output.bitCountAfterFirstOne,testCases[i].binaryVersionOfDecimal]
                )
            );
        }
        return true;
    }

    (:test)
    function UtilTest_invalidInput_getBitsOfDecimal_Test(logger as Toybox.Test.Logger) as Boolean {
        var randomDepth = 10;
        try {
            getBitsOfDecimal(0.123f,{:maximumBits => randomDepth} );//supposed to be a double and a float
        } catch (e instanceof Toybox.Lang.UnexpectedTypeException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting Toybox.Lang.Double argument type as first argument";
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
            getBitsOfDecimal(1d,{:maximumBits => randomDepth} );
        } catch (e instanceof Toybox.Lang.InvalidValueException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting a Toybox.Lang.Double in the range of (0,1) as first argument";
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
            getBitsOfDecimal(-0.123d,{:maximumBits => randomDepth} );
        } catch (e instanceof Toybox.Lang.InvalidValueException) {
            var acquiredErrorMessage = e.getErrorMessage();
            var expectedErrorMessage = "Expecting a Toybox.Lang.Double in the range of (0,1) as first argument";
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
    function UtilTest_longWithFirstNBitsOne_Test(logger as Toybox.Test.Logger) as Boolean {
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsOne(1)),
            [0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsOne(3)),
            [0xE0,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsOne(15)),
            [0xFF,0xFE,0x00,0x00,0x00,0x00,0x00,0x00]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsOne(16)),
            [0xFF,0xFF,0x00,0x00,0x00,0x00,0x00,0x00]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsOne(63)),
            [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFE]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsOne(64)),
            [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]b
        );
        return true;
    }

    (:test)
    function UtilTest_longWithFirstNBitsZero_Test(logger as Toybox.Test.Logger) as Boolean {
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsZero(1)),
            [0x7F,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsZero(3)),
            [0x1F,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsZero(15)),
            [0x00,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsZero(16)),
            [0x00,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsZero(63)),
            [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01]b
        );
        assertEquivalencyBetweenByteArrays(
            BytePacking.Long.longToByteArray(longWithFirstNBitsZero(64)),
            [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b
        );
        return true;
    }

    (:test)
    function UtilTest_getBitsOfFloor_basicTest(logger as Toybox.Test.Logger) as Boolean {
        /*
         70466797557557426969903104.0
         which in float's IEEE 754 binary is
         0 11010100 11010010010011110110011

         If we were to convert to a standard binary (without IEEE 754's exponent section), then the binary would be
         111010010010011110110011, followed by 62 "0"s for a total of 86 binary digits

         which means our FloorData should mention that the number is a total of 86 bits, with 24 bits for the part before
         all the zero's and that the long equivalent (of the 24 bits) is 15280051
        */

        /*
            casting to double is fine as any number that can be represented by float can be represented by double
            https://stackoverflow.com/questions/259015/can-every-float-be-expressed-exactly-as-a-double
        */
        var output = getBitsOfFloor(70466797557557426969903104.0d);
        Test.assert(output.totalBitCount == 86);
        Test.assertMessage(output.bitCountBeforeAllZeros == 24,""+output.bitCountBeforeAllZeros);
        Test.assertMessage(output.long == 15280051, ""+output.long );


        output = getBitsOfFloor(2.0d);
        Test.assert(output.totalBitCount == 2);
        Test.assertMessage(output.bitCountBeforeAllZeros == 1,""+output.bitCountBeforeAllZeros);
        Test.assertMessage(output.long == 1, ""+output.long );


        return true;
    }


}