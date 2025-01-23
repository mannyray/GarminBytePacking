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

        hidden const BITS_IN_FLOAT_EXPONENT = 8;
        hidden const BITS_IN_FLOAT_MANTISSA = 23;
        hidden const FLOAT_EXPONENT_BIAS = 127;

        function floatToByteArray(input as Toybox.Lang.Float) as Toybox.Lang.ByteArray {

            if(!(input instanceof Toybox.Lang.Float) ){
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Float argument type",null,null);
            }

            /*
                Important to track of the 32 bits used to store a float, one of them 
                is reserved for the sign of the number
            */
            var isNegative = input < 0;

            var longEquivalentInBitsOfFloat = 0l;

            
            var nonnegativeIntegerPortionOfFloat = input.abs().toLong();

            if(nonnegativeIntegerPortionOfFloat > 0){//TODO: explain our if statement here
                /*
                    let's say our number in binary decimal is "101.001"
                    thus integerPortion is binary "101" (i.e. 5)
                    which BinaryDataPair stores as long=5,bitCount=3
                */
                var binaryStoreOfNonNegativeIntegerPortion = new BinaryDataPair(nonnegativeIntegerPortionOfFloat);

                /*
                    the BinaryDataPair stores it as bitCount=3, but we subtract one as in float IEEE-754 representation, 
                    the leading "1" bit is assumed and so we can ignore it.
                */
                
                // "101" in binary gets the leading one removed so becomes "1" so the long value becomes 1 in decimal
                //System.println("before " + binaryStoreOfNonNegativeIntegerPortion.long);
                binaryStoreOfNonNegativeIntegerPortion.long = binaryStoreOfNonNegativeIntegerPortion.long & longWithFirstNBitsZero(BITS_IN_LONG - binaryStoreOfNonNegativeIntegerPortion.bitCount+1);
                //System.println("after " + binaryStoreOfNonNegativeIntegerPortion.long);
                //by removing the "1", we adjust bit count
                binaryStoreOfNonNegativeIntegerPortion.bitCount--;
                
                // Bias is a property of the IEEE 754 standard. 
                // our number "101.001" becomes represented as ".01001" * 2^binaryStoreOfNonNegativeIntegerPortion.bitCount = ".01001" * 2^2
                // with the leading "1" being implicit. 2^2 is two bit shifts to the left which would give us back "101.001"
                var exponentValue = FLOAT_EXPONENT_BIAS + binaryStoreOfNonNegativeIntegerPortion.bitCount;
                var exponentValueInProperBitLocation = exponentValue.toLong() << BITS_IN_FLOAT_MANTISSA;


                //System.println("integer portion " + binaryStoreOfNonNegativeIntegerPortion.bitCount);
                // the rest of the decimal part (e.g. "0.001" or 0.125 in decimal) gets to take up the remaining part of the MANTISSA
                var bitsRemainingForDecimal = BITS_IN_FLOAT_MANTISSA - binaryStoreOfNonNegativeIntegerPortion.bitCount;
                //System.println("bitsRemainingForDecimal" + bitsRemainingForDecimal);
                /*
                    now we store the decimal in long format via BinaryDataPair which will be easier for us to manipulate later on
                    "0.001" in binary will be stored in BinaryDataPair as long=1,bitCount=3
                
                    getBitsOfDecimal takes in Doubles, so we cast to Double. This is fine as based on bit structure of a float
                    it can be accurately represented by a double which has a similar bit structure
                    https://stackoverflow.com/questions/259015/can-every-float-be-expressed-exactly-as-a-double
                */

                var decimalPortionInProperBitLocation = 0l;
                var integerPortionInProperBitLocation = 0l;
                if(bitsRemainingForDecimal>0){
                    var binaryStoreOfDecimalPortion = getBitsOfDecimal(
                        (input.abs() - nonnegativeIntegerPortionOfFloat).toDouble(), 
                        bitsRemainingForDecimal
                    );
                    //we might not be using the entire mantissa, so we shift up the decimal portion to follow right after the integer portion.
                    decimalPortionInProperBitLocation = binaryStoreOfDecimalPortion.long << (bitsRemainingForDecimal - binaryStoreOfDecimalPortion.bitCount);
                    // integer bits lead the decimal bits
                    integerPortionInProperBitLocation = binaryStoreOfNonNegativeIntegerPortion.long << bitsRemainingForDecimal; 
                }
                else{
                    // there is only room for the integer portion
                    // TODO: why the negative one? use 16777372 as an example
                    integerPortionInProperBitLocation = binaryStoreOfNonNegativeIntegerPortion.long >> (-1*bitsRemainingForDecimal); 
                }
                longEquivalentInBitsOfFloat = exponentValueInProperBitLocation | integerPortionInProperBitLocation | decimalPortionInProperBitLocation;
            }
            else{
                /*
                    var binaryStoreOfDecimalPortion = getBitsOfDecimal(
                        (input.abs() - nonnegativeIntegerPortionOfFloat).toDouble(), 
                        bitsRemainingForDecimal
                    );
                */
            }

            if(isNegative){
                longEquivalentInBitsOfFloat = longEquivalentInBitsOfFloat | longWithFirstNBitsOne(1);
            }
            /*
                We were doing our bit manipulation usings long due to ease of running bit shifting and logical OR operations
                However, long is 64 bits while float is 32 in our long the float portion is stored in the second half
                which is why we return the slice (i.e. second half of the byte array)
            */
            return BytePacking.Long.longToByteArray(longEquivalentInBitsOfFloat).slice(4,null);
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
            var bitsRequiredToStoreTheNonNegativeIntegerPortion = exponentValueInProperBitLocation.toNumber() - FLOAT_EXPONENT_BIAS;

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