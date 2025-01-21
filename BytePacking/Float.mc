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
            var isNegative = input < 0;

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
            if(isNegative){
                longEquivalent = longEquivalent | longWithFirstNBitsOne(1);
            }
        
            return BytePacking.Long.longToByteArray(longEquivalent).slice(4,null);
        }


        function byteArrayToFloat(input as Toybox.Lang.ByteArray) as Toybox.Lang.Float {
            // TODO assert byte array length
            var buffer = [0x00,0x00,0x00,0x00]b;
            var longEquivalent = BytePacking.Long.byteArrayToLong(buffer.addAll(input));

            //TODO: long bias of 32 bits
            var EMPTY_LONG_BIAS = 32;
            
            var signValueInProperBitLocation = ( longWithFirstNBitsOne(EMPTY_LONG_BIAS + 1) & longEquivalent ) >> (BITS_IN_FLOAT - 1);
            var exponentValueInProperBitLocation = (longWithFirstNBitsZero(EMPTY_LONG_BIAS + 1) & longEquivalent) >> BITS_IN_FLOAT_MANTISSA;
            //System.println("exponent vaue " + exponentValueInProperBitLocation);

            var mantissaValueInProperBitLocation = longWithFirstNBitsZero(EMPTY_LONG_BIAS +1+BITS_IN_FLOAT_EXPONENT ) & longEquivalent;
            //System.print("mantissabitlocation " + mantissaValueInProperBitLocation);

            var justOne = longWithFirstNBitsOne(EMPTY_LONG_BIAS +BITS_IN_FLOAT_EXPONENT+1) & longWithFirstNBitsZero(EMPTY_LONG_BIAS+BITS_IN_FLOAT_EXPONENT);


            //System.print("mantissabitlocation justone " + (mantissaValueInProperBitLocation | justOne));

            var isNegative = signValueInProperBitLocation == 1;
            var bitsRequiredToStoreTheNonNegativeIntegerPortion = exponentValueInProperBitLocation - FLOAT_EXPONENT_BIAS;

            var nonnegativeIntegerPortionOfFloat = (  ( mantissaValueInProperBitLocation | justOne )>> (BITS_IN_FLOAT_MANTISSA - bitsRequiredToStoreTheNonNegativeIntegerPortion) ).toFloat();
            

            var bitsRemainingForDecimalPortion = 64 - ( EMPTY_LONG_BIAS +  1 + BITS_IN_FLOAT_EXPONENT + bitsRequiredToStoreTheNonNegativeIntegerPortion);
            var binaryStoreOfDecimalPortion = longWithFirstNBitsZero(EMPTY_LONG_BIAS +  1 + BITS_IN_FLOAT_EXPONENT + bitsRequiredToStoreTheNonNegativeIntegerPortion) & longEquivalent;

            var bdp = new BinaryDataPair(binaryStoreOfDecimalPortion);
            bdp.bitCount = bitsRemainingForDecimalPortion; //TODO: cleanup

            var decimalPortionOfFloat = getDecimalOfBits(bdp);

            var output = nonnegativeIntegerPortionOfFloat + decimalPortionOfFloat.toFloat();
            if(isNegative){
                output = output * -1;
            }

            return output;
        }
    }
}