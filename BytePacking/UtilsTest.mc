using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;

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
                Following two test cases are mirrors are the of the two prior but with the difference being in
                maxArgument. We achieve the exact same output in the longEquivalent equivalent by just modifying 
                maximumBitsAfterLeadingZeros to exclude the leading zero count.
            */
            new GetBitsOfDecimal_TestCase({
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBitsAfterLeadingZeros=>7},
                    :bitsRequired=>10,
                    :bitsAfterFirstOne=>7,
                    :longEquivalent=>102l,
                    :binaryVersionOfDecimal=>"0.0001100110",
                    :binaryWithoutLeadingZeros=>"1100110",
                    :truncatedValueOfBinaryInDouble=>0.099609375d
            }),            
            new GetBitsOfDecimal_TestCase({
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBitsAfterLeadingZeros=>17},
                    :bitsRequired=>20,
                    :bitsAfterFirstOne=>17,
                    :longEquivalent=>104857l,
                    :binaryVersionOfDecimal=>"0.00011001100110011001",
                    :binaryWithoutLeadingZeros=>"11001100110011001",
                    :truncatedValueOfBinaryInDouble=>0.09999942779541015625d
            }), 
            new GetBitsOfDecimal_TestCase({
                    :doubleInput=>0.1d,
                    :maxArgument=>{:maximumBitsAfterLeadingZeros=>0},
                    :bitsRequired=>0,
                    :bitsAfterFirstOne=>0,
                    :longEquivalent=>0l,
                    :binaryVersionOfDecimal=>"0.0",
                    :binaryWithoutLeadingZeros=>"0",
                    :truncatedValueOfBinaryInDouble=>0d
            }),
        ];
        for(var i=0; i<testCases.size(); i++){

            var output =  DecimalData.getBitsOfDecimal(testCases[i].double,testCases[i].maxArgument );
            Test.assertEqualMessage(output.getTotalBitCount(),testCases[i].bitsRequired,
                Toybox.Lang.format(
                    "Requiring $1$ bits to store $2$ (binary version: $3$), but got $4$ bits computed.",
                    [testCases[i].bitsRequired,testCases[i].double,testCases[i].binaryVersionOfDecimal,output.getTotalBitCount()]
                )
            );
            Test.assertEqualMessage(output.getLongEquivalent(),testCases[i].longEquivalent,
                Toybox.Lang.format(
                    "Long stored version of $1$ should be $3$ (or in binary $2$), but got $4$",
                    [testCases[i].double,testCases[i].binaryVersionOfDecimal,testCases[i].longEquivalent,output.getLongEquivalent()]
                )
            );
            Test.assertEqualMessage(output.getDecimalOfBits(),testCases[i].truncatedValueOfBinaryInDouble,
                Toybox.Lang.format(
                    "Truncated double version of $1$ should be $2$, but got $3$",
                    [testCases[i].double,testCases[i].truncatedValueOfBinaryInDouble,output.getDecimalOfBits()]
                )
            );
            Test.assertEqualMessage(output.getBitCountAfterLeadingZeros(),testCases[i].bitsAfterFirstOne,
                Toybox.Lang.format(
                    "Truncated version of $1$ should has $2$ bits after first one, but got $3$ for the binary decimal $4$",
                    [testCases[i].truncatedValueOfBinaryInDouble,testCases[i].bitsAfterFirstOne,output.getBitCountAfterLeadingZeros(),testCases[i].binaryVersionOfDecimal]
                )
            );
        }
        return true;
    }

    (:test)
    function UtilTest_invalidInput_getBitsOfDecimal_Test(logger as Toybox.Test.Logger) as Boolean {
        var randomDepth = 10;
        try {
            DecimalData.getBitsOfDecimal(0.123f,{:maximumBits => randomDepth} );//supposed to be a double and a float
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
            DecimalData.getBitsOfDecimal(1d,{:maximumBits => randomDepth} );
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
            DecimalData.getBitsOfDecimal(-0.123d,{:maximumBits => randomDepth} );
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

        var invalidDictionaries = [ 
            0.1d,
            [],
            {},
            {:random=>1},
            {:maximumBitsAfterLeadingZeros=>1,:maximumBits=>2},
            {"maximumBitsAfterLeadingZeros"=>1},
            {:maximumBitsAfterLeadingZeros=>-1},
            {:maximumBitsAfterLeadingZeros=>1.0},
            {:maximumBits=>-1},
            {:maximumBits=>1.0},
            ];
        var expectedErrorMessages = [
            "Expecting Toybox.Lang.Dictionary argument type as second argument",
            "Expecting Toybox.Lang.Dictionary argument type as second argument",
            "Expecting a Toybox.Lang.Dictionary of size of 1 with one of maximumBitsAfterLeadingZeros or maximumBits defined",
            "Expecting a Toybox.Lang.Dictionary of size of 1 with one of maximumBitsAfterLeadingZeros or maximumBits defined",
            "Expecting a Toybox.Lang.Dictionary of size of 1 with one of maximumBitsAfterLeadingZeros or maximumBits defined",
            "Expecting a Toybox.Lang.Dictionary of size of 1 with one of maximumBitsAfterLeadingZeros or maximumBits defined",
            "maximumBitsAfterLeadingZeros must be a Toybox.Lang.Number greater than or equal to zero",
            "maximumBitsAfterLeadingZeros must be a Toybox.Lang.Number greater than or equal to zero",
            "maximumBits must be a Toybox.Lang.Number greater than or equal to zero",
            "maximumBits must be a Toybox.Lang.Number greater than or equal to zero",
        ];

        for(var i=0; i<invalidDictionaries.size(); i++ ){
            try {
                DecimalData.getBitsOfDecimal(0.123d,invalidDictionaries[i] );
            } catch (e instanceof Toybox.Lang.Exception) {
                var acquiredErrorMessage = e.getErrorMessage();
                var expectedErrorMessage = expectedErrorMessages[i];
                Test.assertMessage(
                    acquiredErrorMessage.find(expectedErrorMessage) != null,
                    "Invalid error message. Got '" +
                    acquiredErrorMessage +
                    "', expected: '" +
                    expectedErrorMessage +
                    "'"
                );
            }
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
        var testDicts = [
            {
                :input=>70466797557557426969903104.0d,
                :expectedTotalBitCount=>86,
                :expectedBitCountBeforeTrailingZeros=>24,
                :expectedLongEquivalent=>15280051l,
                :expectedTrailingZeroCount=>62,
            },
            {
                :input=>2.0d,
                :expectedTotalBitCount=>2,
                :expectedBitCountBeforeTrailingZeros=>1,
                :expectedLongEquivalent=>1l,
                :expectedTrailingZeroCount=>1,
            },
            {
                :input=>1.0d,
                :expectedTotalBitCount=>1,
                :expectedBitCountBeforeTrailingZeros=>1,
                :expectedLongEquivalent=>1l,
                :expectedTrailingZeroCount=>0,
            },
            {
                :input=>9587.0d,
                :expectedTotalBitCount=>14,
                :expectedBitCountBeforeTrailingZeros=>14,
                :expectedLongEquivalent=>9587l,
                :expectedTrailingZeroCount=>0,
            },
        ];
        for(var i=0; i<testDicts.size(); i++){
            var output = FloorData.getBitsOfFloor(testDicts[i][:input]);
            Test.assert(output.getTotalBitCount() == testDicts[i][:expectedTotalBitCount]);
            Test.assert(output.getBitCountBeforeTrailingZeros() == testDicts[i][:expectedBitCountBeforeTrailingZeros]);
            Test.assert(output.getLongEquivalent() == testDicts[i][:expectedLongEquivalent]);
            Test.assert(output.getTrailingZeroCount() == testDicts[i][:expectedTrailingZeroCount]);
            Test.assert(output.getFloorOfBits() == testDicts[i][:input]);
        }
        return true;
    }

    (:test)
    function UtilTest_newFloorData_basicTest(logger as Toybox.Test.Logger) as Boolean {
        var testDicts = [
            {
                :longInput=>1l,
                :totalBitCountInput=>1,
                :expectedLongEquivalent=>1,
                :getBitCountBeforeTrailingZeros=>1,
            },
            {
                :longInput=>5l,
                :totalBitCountInput=>3,
                :expectedLongEquivalent=>5,
                :getBitCountBeforeTrailingZeros=>3,
            },
            {
                :longInput=>10l,
                :totalBitCountInput=>4,
                :expectedLongEquivalent=>5,
                :getBitCountBeforeTrailingZeros=>3,
            },
        ];
        for(var i=0; i<testDicts.size();i++){
            var output = FloorData.newFloorData(testDicts[i][:longInput],testDicts[i][:totalBitCountInput]);
            Test.assert(output.getLongEquivalent()==testDicts[i][:expectedLongEquivalent]);
            Test.assert(output.getBitCountBeforeTrailingZeros()==testDicts[i][:getBitCountBeforeTrailingZeros] );
        }
        return true;
    }


    (:test)
    function UtilTest_invalidInput_getBitsOfFloor_Test(logger as Toybox.Test.Logger) as Boolean {
        var wrongInputs = [
            1f,
            1,
            123.01d,
            -123d,
            Math.acos(45d),
        ];
        var expectedErrors = [
            "Expecting Toybox.Lang.Double argument type as argument",
            "Expecting Toybox.Lang.Double argument type as argument",
            "Expecting a Toybox.Lang.Double without anything after the '.'",
            "Expecting a greater than zero Toybox.Lang.Double",
            "Toybox.Lang.Double input can't be a 'nan'",
        ];
        for(var i=0; i<wrongInputs.size();i++){
            try {
                FloorData.getBitsOfFloor(wrongInputs[i]);//supposed to be a double and a float
            } catch (e instanceof Toybox.Lang.Exception) {
                var acquiredErrorMessage = e.getErrorMessage();
                var expectedErrorMessage = expectedErrors[i];
                Test.assertMessage(
                    acquiredErrorMessage.find(expectedErrorMessage) != null,
                    "Invalid error message. Got '" +
                    acquiredErrorMessage +
                    "', expected: '" +
                    expectedErrorMessage +
                    "'"
                );
            }
        }
        return true;
    }

    (:test)
    function UtilTest_nan_inf_Test(logger as Toybox.Test.Logger) as Boolean {
        Test.assert(!isnan(1d));
        Test.assert(!isnan(1f));
        Test.assert(isnan(Math.acos(45d)));

        var infArr = [0x7f,0x80, 0x00, 0x00]b;
        Test.assert(isinf(infArr.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:offset => 0, :endianness=>Lang.ENDIAN_BIG})));
        return true;
    }
}