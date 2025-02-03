import Toybox.Lang;
import Toybox.System;
import Toybox.Math;

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
        hidden const MINIMAL_FLOAT_EXPONENT = -127;
        hidden const BITS_IN_SIGN = 1;

        hidden const LEADING_ONE_OUTSIDE_MANTISSA_BIT = 1;
        hidden const SHIFT_DUE_TO_FLOAT=32;

        /*
            Converts a float to ENDIAN_BIG style format.
            See https://www.h-schmidt.net/FloatConverter/IEEE754.html for example.
        */
        function floatToByteArray(input as Toybox.Lang.Float) as Toybox.Lang.ByteArray {

            var BITS_IN_MANTISSA = BITS_IN_FLOAT_MANTISSA;
            var MINIMAL_EXPONENT = MINIMAL_FLOAT_EXPONENT;
            var EXPONENT_BIAS = FLOAT_EXPONENT_BIAS;
            var BITS_IN_EXPONENT = BITS_IN_FLOAT_EXPONENT;
            var PARSING_SHIFT = SHIFT_DUE_TO_FLOAT;

            if(!(input instanceof Toybox.Lang.Float) ){
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Float argument type",null,null);
            }
            if(isnan(input) or isinf(input)){
                throw new Toybox.Lang.InvalidValueException("Input cannot be inf or nan");
            }
            if( input.toDouble() == 0){
                // special sepate case, because the exponent is set to zero
                return [0x00,0x00,0x00,0x00]b;
            }

            var longEquivalentInBitsOfInput = 0l;
            var isNegative = input < 0;
            var nonnegativeIntegerPortionOfInput = Math.floor(input.abs());
            if(nonnegativeIntegerPortionOfInput > 0){
                /*
                    Our float has a >0 positive integer portion which means our mantissa code block
                    could be storing bits from the integer and decimal portion.

                    For example float's IEEE 754 biary for 123.125 is
                    01000010111101100100000000000000 where 11101100100000000000000 is for mantissa
                    which we split with 111011 00100000000000000 with 
                    111011 for 123 (the leading binary "1" removed as it is implicit) and 
                    00100000000000000 for 0.123.

                    To compute the binary for the integer portion we use FloorData.getBitsOfFloor
                    while computing binary version of decimal we use DecimalData.getBitsOfDecimal where the former uses
                    division and latter multipication for binary computation. Due to underlying 
                    difference in binary computation methods, we are explicit with how we break down 
                    our input in this code.
                    
                    Perhaps there is an overall more efficient, code golf like
                    way of converting a float/double to binary, but we choose to be very expicilit and verbose here
                    for educational purposes.
                */
                
                /*
                    let's say our number in binary decimal is "1010.001" thus integerPortion is binary "1010" (i.e. 10)
                    which FloorData stores. See FloorData class for details.
                */
                var floorData = FloorData.getBitsOfFloor(nonnegativeIntegerPortionOfInput.toDouble());

                /*
                    We remove the leading "1" bit as it is assumed (implicit in IEEE 754 format) and so we can ignore it.
                    example: "1010" in binary gets the leading one removed so becomes "010" so the long value becomes 2 in decimal.:__version
                    
                    Removing the leading one, changes the floorData.getTotalBitCount() by minus one.
                */
                floorData.removeLeadingBit();
                
                /*
                    Our number "1010", with the leading bit removed is "010".
                    We represent this as ".010" * 2^3 = ".010" * 2^floorData.getTotalBitCount()

                    floorData.getTotalBitCount() thus is our exponent value to which we add
                    IEEE 754's bias value of EXPONENT_BIAS
                */
                var exponentValue = EXPONENT_BIAS + floorData.getTotalBitCount();
                //  we move the exponent value is to the left of the mantissa block
                var exponentValueInProperBitLocation = exponentValue.toLong() << BITS_IN_MANTISSA;


                // the rest of the decimal part (e.g. "0.001" of "1010.001" or 0.125 in decimal) gets to take up the remaining part of the MANTISSA
                var bitsRemainingForDecimal = BITS_IN_MANTISSA - floorData.getTotalBitCount();

                // first part of mantissa is for the integer portion and second is for the decimal portion
                var decimalPortionInProperBitLocation = 0l;
                var integerPortionInProperBitLocation = 0l;

                if(bitsRemainingForDecimal>0){
                    var decimalData = DecimalData.getBitsOfDecimal(
                        /*
                            getBitsOfDecimal takes in Doubles, so we cast to Double. This is fine as based on bit structure of a float
                            it can be accurately represented by a double which has a similar bit structure
                            https://stackoverflow.com/questions/259015/can-every-float-be-expressed-exactly-as-a-double
                        */
                        (input.abs() - nonnegativeIntegerPortionOfInput).toDouble(), 
                        {:maximumBits => bitsRemainingForDecimal}
                    );
                    /*
                        Since, we specified bitsRemainingForDecimal to be exactly bitsRemainingForDecimal then the binary amount to represent the decimal portion
                        (aka binaryStoreOfDecimalPortion.totalBitCount) may be less than or equal to bitsRemainingForDecimal.
                        Therefore we might not be using the entire bitsRemainingForDecimal, so we shift up the decimal portion to follow right after the integer portion.
                    */
                    decimalPortionInProperBitLocation = decimalData.getLongEquivalent() << (bitsRemainingForDecimal - decimalData.getTotalBitCount());
                    // integer bits goes before the decimal bits
                    integerPortionInProperBitLocation = floorData.getLongEquivalent() << (bitsRemainingForDecimal + (floorData.getTrailingZeroCount())); 
                }
                else{// else - meaining there is only room for the integer portion of the float
                    
                    if(floorData.getBitCountBeforeTrailingZeros()>BITS_IN_MANTISSA){
                        // For our number, the integer portion may have more bits to be stored then available in MANTISSA portion, so we overwrite the smallest
                        // ones by shifting them out of range
                        integerPortionInProperBitLocation = floorData.getLongEquivalent() >> (floorData.getBitCountBeforeTrailingZeros()-BITS_IN_MANTISSA); 
                    }
                    else{
                        // For our number, the integer portion may have way less bits than available in MANTISSA so we left shift it so that our number encoding
                        // starts right where the MANTISSA bits start
                        integerPortionInProperBitLocation = floorData.getLongEquivalent() << (BITS_IN_MANTISSA-floorData.getBitCountBeforeTrailingZeros()); 
                    }
                }
                /*
                    For example used above of 0 10000101 11101100100000000000000 
                    we have 
                    exponentValueInProperBitLocation  0 10000101 00000000000000000000000
                    integerPortionInProperBitLocation 0 00000000 11101100000000000000000
                    decimalPortionInProperBitLocation 0 10000101 00000000100000000000000

                    by logical ORing the components we combine the number together
                */
                longEquivalentInBitsOfInput = exponentValueInProperBitLocation | integerPortionInProperBitLocation | decimalPortionInProperBitLocation;
            }
            else{ // We are allowed to use all mantissa bits for the decimal portion as there is no integer portion
                
                //plus LEADING_ONE_OUTSIDE_MANTISSA_BIT because the first bit is "free" or "implicit" in IEEE 754 notation
                var decimalData = DecimalData.getBitsOfDecimal(input.abs().toDouble(), {:maximumBitsAfterLeadingZeros => BITS_IN_MANTISSA+LEADING_ONE_OUTSIDE_MANTISSA_BIT});
                var decimalPortionInProperBitLocation = decimalData.getLongEquivalent();

                /*
                    Say our binary decimal is "0.0010101" which means we need totalBitCount is 7 (numbers to the right of ".")
                    while bitCountAfterFirstOne is 5 (to store the tailing "10101"). This can be summarized
                    as "10101.0" * 2^{-7} or (where the "101" is in binary - each -1 in exponent shifts to the right one)
                    or as "1.0101" * 2^{-3} (where -3 is the leaps to get the number so that leading "1" is to left of the ".")
                    we compute, aka "exponentValue" (e.g. -3), as the number of zeros till the leading one in "0.0010101"
                    which is (decimalData.bitCountAfterFirstOne - decimalData.totalBitCount) and then subtract the
                    additional -1 to get the leading one "1" over the "."
                */
                var exponentValue = decimalData.getBitCountAfterLeadingZeros() - decimalData.getTotalBitCount()-LEADING_ONE_OUTSIDE_MANTISSA_BIT;

                if( decimalData.getBitCountAfterLeadingZeros() < BITS_IN_MANTISSA+LEADING_ONE_OUTSIDE_MANTISSA_BIT){
                    /*
                        the digits required to store the decimal portion are smaller than the permitted 
                        amount in MANTISSA. To account for this we just left shift all the value and the tail end
                        will be padded with zeros. We add the plus one, because the leading binary one is "Free"
                        in IEEE 754 notation.
                    */
                    var shift = 0;
                    if(exponentValue > MINIMAL_EXPONENT){
                        /*
                            'the leading binary one is "Free"' (i.e. LEADING_ONE_OUTSIDE_MANTISSA_BIT here below) is only true for non subnormal numbers
                            https://en.wikipedia.org/wiki/Subnormal_number where subnormals
                            have an exponent equal to MINIMAL_EXPONENT
                        */
                        shift = (BITS_IN_MANTISSA - decimalData.getBitCountAfterLeadingZeros())+LEADING_ONE_OUTSIDE_MANTISSA_BIT;
                    }
                    else{
                        // subnormal number
                        //example: 0 00000000 10101001100100100100010 = 7.786335e-39
                        //Mantissa is not zero and exponent part is, and the leading bit is assumed to be 0 instead of the usual 1
                        shift = (BITS_IN_MANTISSA - decimalData.getBitCountAfterLeadingZeros() - (exponentValue+EXPONENT_BIAS).abs());
                        exponentValue = MINIMAL_EXPONENT;
                    }
                    decimalPortionInProperBitLocation = decimalPortionInProperBitLocation << shift;
                }

                /*
                    This makes sure the space reserved for exponent and sign bit are all 0s including the "free" leading one of the mantissa portion.
                    They may not be free, because of the " << shift" ran above OR the case where our leading one is outside mantissa portion 
                    due to "decimalData.getBitCountAfterLeadingZeros() == BITS_IN_MANTISSA+LEADING_ONE_OUTSIDE_MANTISSA_BIT" condition.
                    PARSING_SHIFT in case we are manipulating longs which are 64 bits long, while we are only working the tail 32 bits for floats
                */
                decimalPortionInProperBitLocation = decimalPortionInProperBitLocation && longWithFirstNBitsZero(PARSING_SHIFT + BITS_IN_EXPONENT + BITS_IN_SIGN);

                var exponentValueInProperBitLocation = (exponentValue + EXPONENT_BIAS).toLong() << BITS_IN_MANTISSA;
                longEquivalentInBitsOfInput = exponentValueInProperBitLocation | decimalPortionInProperBitLocation;
            }

            if(isNegative){
                // The leading bit in IEEE 754 is for the sign. If negative, we turn this bit ON.
                longEquivalentInBitsOfInput = longEquivalentInBitsOfInput | longWithFirstNBitsOne(PARSING_SHIFT + BITS_IN_SIGN);
            }
            /*
                We were doing our bit manipulation usings long due to ease of running bit shifting and logical OR operations
                However, long is 64 bits while float is 32 in our long the float portion is stored in the second half
                which is why we return the slice (i.e. second half of the byte array)
            */
            return BytePacking.Long.longToByteArray(longEquivalentInBitsOfInput).slice(BytePacking.BYTES_IN_FLOAT,null);
        }



        function byteArrayToFloat(input as Toybox.Lang.ByteArray) as Toybox.Lang.Float {
            // TODO: input validation

            // TODO: inf/nan check

            // all zeros? return 0f
            var allZerosFourBytes = [0x00,0x00,0x00,0x00]b;
            if(input == allZerosFourBytes){ // TODO test this
                return 0f;
            }

            var output = 0f;
            var longEquivalent = BytePacking.Long.byteArrayToLong(allZerosFourBytes.addAll(input));
            

            var isNegative = (longEquivalent >> (SHIFT_DUE_TO_FLOAT - 1)) == 1l;
            // now remove the sign bit
            longEquivalent = longEquivalent & longWithFirstNBitsZero( SHIFT_DUE_TO_FLOAT + 1);
            var exponentValue = (longEquivalent >> BITS_IN_FLOAT_MANTISSA) - FLOAT_EXPONENT_BIAS;

            var mantissaLong = ( longEquivalent ) & longWithFirstNBitsZero(64-23) ;
            var mantissaLeadingOne = 1l << BITS_IN_FLOAT_MANTISSA;
            mantissaLong = mantissaLong | mantissaLeadingOne;
            System.println("a " + exponentValue);
            if(exponentValue >= 0){
                System.println("herehere");
                if(exponentValue >= BITS_IN_FLOAT_MANTISSA){
                    // purely an integer

                    System.println(mantissaLong);
                    var newFloorData = FloorData.newFloorData(mantissaLong,exponentValue+1);

                    output = newFloorData.getFloorOfBits();
                }
            }
            System.println("done");

            // if exponent value > 0 then we have integer portion
            /*
            exponent value will tell us by how much we have to shift the mantissa long portion to the right where we also append a leading one
            if exponent value < a certain number then we have decimal portion as well 
            */

            // else it is all just decimal
            /*
            ... subnormal handle if exponent equals minimal we assume leading 0, otherwise we assuming leading one
            */

            //TODO test inf/nan
            if(isNegative){
                output = output * -1;
            }
            return output;
        }
    }
}