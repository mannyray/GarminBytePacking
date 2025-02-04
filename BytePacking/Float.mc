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

    class BPFloat extends Toybox.Lang.Float{

        function initialize(){
            Float.initialize();
        }

        /*
            Converts a float to ENDIAN_BIG style format.
            See https://www.h-schmidt.net/FloatConverter/IEEE754.html for example.
            
        */
        static function floatToByteArray(input as Toybox.Lang.Float) as Toybox.Lang.ByteArray {
            if(!(input instanceof Toybox.Lang.Float) ){
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Float argument type",null,null);
            }

            if( input.toDouble() == 0d){
                // special separate case, because the exponent is set to zero
                return [0x00,0x00,0x00,0x00]b;
            }

            var BITS_IN_MANTISSA = BytePacking.BITS_IN_FLOAT_MANTISSA;
            var MINIMAL_EXPONENT = BytePacking.MINIMAL_FLOAT_EXPONENT;
            var EXPONENT_BIAS = BytePacking.FLOAT_EXPONENT_BIAS;
            var BITS_IN_EXPONENT = BytePacking.BITS_IN_FLOAT_EXPONENT;
            var PARSING_SHIFT = BytePacking.SHIFT_DUE_TO_FLOAT;

            return genericToByteArray(input.toDouble(),BITS_IN_MANTISSA,MINIMAL_EXPONENT,EXPONENT_BIAS,BITS_IN_EXPONENT,PARSING_SHIFT);
        }

        static function genericToByteArray(input as Toybox.Lang.Double,
            BITS_IN_MANTISSA as Toybox.Lang.Number,
            MINIMAL_EXPONENT as Toybox.Lang.Number,
            EXPONENT_BIAS as Toybox.Lang.Number,
            BITS_IN_EXPONENT as Toybox.Lang.Number,
            PARSING_SHIFT as Toybox.Lang.Number
        ) as Toybox.Lang.ByteArray {
           
            if(isnan(input) or isinf(input)){
                throw new Toybox.Lang.InvalidValueException("Input cannot be inf or nan");
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
                var decimalData = DecimalData.getBitsOfDecimal(input.abs().toDouble(), {:maximumBitsAfterLeadingZeros => BITS_IN_MANTISSA+BytePacking.LEADING_ONE_OUTSIDE_MANTISSA_BIT});
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
                var exponentValue = decimalData.getBitCountAfterLeadingZeros() - decimalData.getTotalBitCount()-BytePacking.LEADING_ONE_OUTSIDE_MANTISSA_BIT;

                if( decimalData.getBitCountAfterLeadingZeros() < BITS_IN_MANTISSA+BytePacking.LEADING_ONE_OUTSIDE_MANTISSA_BIT){
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
                        shift = (BITS_IN_MANTISSA - decimalData.getBitCountAfterLeadingZeros())+BytePacking.LEADING_ONE_OUTSIDE_MANTISSA_BIT;
                    }
                    else{
                        // subnormal number
                        //example: 0 00000000 10101001100100100100010 = x
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
                decimalPortionInProperBitLocation = decimalPortionInProperBitLocation & longWithFirstNBitsZero(PARSING_SHIFT + BITS_IN_EXPONENT + BytePacking.BITS_IN_SIGN);

                var exponentValueInProperBitLocation = (exponentValue + EXPONENT_BIAS).toLong() << BITS_IN_MANTISSA;
                longEquivalentInBitsOfInput = exponentValueInProperBitLocation | decimalPortionInProperBitLocation;
            }

            if(isNegative){
                // The leading bit in IEEE 754 is for the sign. If negative, we turn this bit ON.
                longEquivalentInBitsOfInput = longEquivalentInBitsOfInput | longWithFirstNBitsOne(PARSING_SHIFT + BytePacking.BITS_IN_SIGN);
            }
            
            if(PARSING_SHIFT == BytePacking.SHIFT_DUE_TO_FLOAT){
                /*
                    We were doing our bit manipulation usings long due to ease of running bit shifting and logical OR operations
                    However, long is 64 bits while float is 32 in our long the float portion is stored in the second half
                    which is why we return the slice (i.e. second half of the byte array)
                */
                return BytePacking.BPLong.longToByteArray(longEquivalentInBitsOfInput).slice(BytePacking.BYTES_IN_FLOAT,null);
            }
            // for the double case
            return BytePacking.BPLong.longToByteArray(longEquivalentInBitsOfInput);
        }

        static function byteArrayToFloat(input as Toybox.Lang.ByteArray) as Toybox.Lang.Float{

            if(!(input instanceof Toybox.Lang.ByteArray) ){
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.ByteArray argument type",null,null);
            }

            if(input.size()!=BytePacking.BYTES_IN_FLOAT){
                throw new Toybox.Lang.InvalidValueException("Need 4 bytes to convert to float");
            }

            var allZerosFourBytes = [0x00,0x00,0x00,0x00]b;
            if(input == allZerosFourBytes){
                return 0f;
            }
            var BITS_IN_MANTISSA = BytePacking.BITS_IN_FLOAT_MANTISSA;
            var MINIMAL_EXPONENT = BytePacking.MINIMAL_FLOAT_EXPONENT;
            var EXPONENT_BIAS = BytePacking.FLOAT_EXPONENT_BIAS;
            var PARSING_SHIFT = BytePacking.SHIFT_DUE_TO_FLOAT;
            var ALL_ONES_EXPONENT = BytePacking.FLOAT_ALL_ONES_EXPONENT;

            return byteArrayToGeneric(input,BITS_IN_MANTISSA,MINIMAL_EXPONENT,EXPONENT_BIAS,PARSING_SHIFT,ALL_ONES_EXPONENT).toFloat();
        }

        static function byteArrayToGeneric(input as Toybox.Lang.ByteArray,
            BITS_IN_MANTISSA as Toybox.Lang.Number,
            MINIMAL_EXPONENT as Toybox.Lang.Number,
            EXPONENT_BIAS as Toybox.Lang.Number,
            PARSING_SHIFT as Toybox.Lang.Number,
            ALL_ONES_EXPONENT as Toybox.Lang.Number
        ) as Toybox.Lang.Double {

            var output = 0f;

            // we convert to long as longs are useful for bit manitpulation operators (>>,>>,|,&) and
            // since float array is 4 bytes we add another 4 for a succesfull to long conversion.
            // We will ignore the tail bits.
            if(PARSING_SHIFT!=0){
                var allZerosFourBytes = [0x00,0x00,0x00,0x00]b;
                input = allZerosFourBytes.addAll(input);
            }
            var longEquivalent = BytePacking.BPLong.byteArrayToLong(input);
            
            // if leading bit is '1' then it is a negative number. We shift to make this comparison
            var isNegative = false;
            if(PARSING_SHIFT!=32){
                // its a double
                isNegative = ( longEquivalent & longWithFirstNBitsOne(1) )  == (1l <<  (BITS_IN_DOUBLE - 1));
            }
            else{
                isNegative = (longEquivalent >> (PARSING_SHIFT - 1)) == 1l;
            }
            // now remove the sign bit
            longEquivalent = longEquivalent & longWithFirstNBitsZero( PARSING_SHIFT + BITS_IN_SIGN );

            // As sign bit is removed, we remove the tail mantissa portion to get the middle exponent value portion
            var exponentValue = ( (longEquivalent >> BITS_IN_MANTISSA) - EXPONENT_BIAS ).toNumber();

            if(exponentValue + EXPONENT_BIAS == ALL_ONES_EXPONENT){
                throw new Toybox.Lang.InvalidValueException("Exponent all 1's - we don't deal with nans/infs");
            }

            //TODO: generalize for double and float

            // we isolate the mantissa from all the other bits
            var mantissaLong = ( longEquivalent ) & longWithFirstNBitsZero(BITS_IN_LONG-BITS_IN_MANTISSA) ;

            // Here we are adding the leading one bit, that is assumed to the left of the mantissa
            var mantissaLeadingOne = 1l << BITS_IN_MANTISSA;
            mantissaLong = mantissaLong | mantissaLeadingOne;

            if(exponentValue >= 0){
                /*
                    The decimal valie will have something to left of the decimal (e.g. 123 in 123.3453).
                    
                    We split our logic to parse both sides of the "."
                */
                var integerPortionMantissaLong = mantissaLong;
                var doublePortionMantissaLong = 0l;

                if(exponentValue < BITS_IN_MANTISSA){
                    /*
                        The exponent value is small enough that not all the mantissa bits are used
                        for the integer portion which is why we now compute the decimal portion
                        (e.g. the 3454 in 123.3453)
                    */

                    // make sure integer portion bits only contain integer portion bits
                    integerPortionMantissaLong = mantissaLong >> (BITS_IN_MANTISSA - exponentValue);

                    //  the rest of the bits are for computing the decimal
                    doublePortionMantissaLong = mantissaLong & longWithFirstNBitsZero(BITS_IN_LONG-BITS_IN_MANTISSA+exponentValue);
                    var newDecimalData = DecimalData.newDecimalData(doublePortionMantissaLong,BITS_IN_MANTISSA-exponentValue );
                    output = output + newDecimalData.getDecimalOfBits();
                }

                var newFloorData = FloorData.newFloorData(integerPortionMantissaLong,exponentValue+BytePacking.LEADING_ONE_OUTSIDE_MANTISSA_BIT);
                output = output +  newFloorData.getFloorOfBits();
                
            }
            else{ // it's all just decimal.
                if(exponentValue > MINIMAL_EXPONENT){
                    var newDecimalData = DecimalData.newDecimalData(mantissaLong,(exponentValue).abs() + BITS_IN_MANTISSA );
                    output = output + newDecimalData.getDecimalOfBits();
                }
                else{
                    // subnormal case where the leading one must be replaced with a leading zero
                    var mantissaLeadingZero = longWithFirstNBitsZero(BITS_IN_LONG-BITS_IN_MANTISSA) & mantissaLong;
                    
                    var newDecimalData = DecimalData.newDecimalData(mantissaLeadingZero,(exponentValue).abs() + BITS_IN_MANTISSA - BytePacking.LEADING_ONE_OUTSIDE_MANTISSA_BIT);
                    output = output + newDecimalData.getDecimalOfBits();
                }
            }            

            
            if(isNegative){
                output = output * -1;
            }
            return output.toDouble();
        }
    }
}