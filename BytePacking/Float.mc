import Toybox.Lang;
import Toybox.System;

module BytePacking{

    /*
        Inspiration for code from
        https://forums.garmin.com/developer/connect-iq/f/discussion/242554/64bit-double-float-to-bytearray
        and
        https://www.wikihow.com/Convert-a-Number-from-Decimal-to-IEEE-754-Floating-Point-Representation
    */


    class Float extends Toybox.Lang.Float{
        hidden const BYTE_SIZE as Number = 8;// TODO put this in some more global file?
        hidden const BITS_IN_FLOAT as Number = 32;
        hidden const BYTES_IN_FLOAT as Number = BITS_IN_FLOAT/BYTE_SIZE;

        hidden const BITS_IN_FLOAT_EXPONENT = 8;
        hidden const BITS_IN_FLOAT_MANTISSA = 23;
        hidden const FLOAT_EXPONENT_BIAS = 127;


        function floatToByteArray(input as Toybox.Lang.Float) as Toybox.Lang.ByteArray {

            if(!(input instanceof Toybox.Lang.Float) ){
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Float argument type",null,null);
            }

            var byteArray = new[BytePacking.Float.BYTES_IN_FLOAT]b;//b for byte data type

            /*
                Important to track of the 32 bits used to store a float, one of them 
                is reserved for the sign of the number
            */
            var isNegative = input < 0; // TODO:

            /*
                in binary, reading from the left most bit, this would be all zeros
                up until the leading "1" of the binary at which point the number begins
            */
            var nonnegativeIntegerPortionOfFloat = input.abs().toLong();
            var binaryStoreOfNonNegativeIntegerPortion = new BinaryDataPair(nonnegativeIntegerPortionOfFloat);

            var bitsRequiredToStoreTheNonNegativeIntegerPortion = binaryStoreOfNonNegativeIntegerPortion.bitCount - 1;
            var bitsRemainingForDecimal = BITS_IN_FLOAT_MANTISSA - bitsRequiredToStoreTheNonNegativeIntegerPortion;

            var binaryStoreOfDecimalPortion = getBitsOfDecimal(
                (input.abs() - nonnegativeIntegerPortionOfFloat).toDouble(), // TODO: is this okay?
                bitsRemainingForDecimal
            );

            var exponentValue = FLOAT_EXPONENT_BIAS + bitsRequiredToStoreTheNonNegativeIntegerPortion;
            var exponentValueInProperBitLocation = exponentValue.toLong() << BITS_IN_FLOAT_MANTISSA;
            var integerPortionInProperBitLocation = binaryStoreOfNonNegativeIntegerPortion.long << bitsRemainingForDecimal;
            var decimalPortionInProperBitLocation = binaryStoreOfDecimalPortion.long;

            var longEquivalent = exponentValueInProperBitLocation | integerPortionInProperBitLocation | decimalPortionInProperBitLocation;

            return BytePacking.Long.longToByteArray(longEquivalent).slice(4,null);
        }
    }
}