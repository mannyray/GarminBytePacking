import Toybox.Lang;
import Toybox.System;

module BytePacking{

    /*
        Inspiration for code from
        https://forums.garmin.com/developer/connect-iq/f/discussion/242554/64bit-double-float-to-bytearray
        and
        https://www.wikihow.com/Convert-a-Number-from-Decimal-to-IEEE-754-Floating-Point-Representation
    */
    class BPDouble extends Toybox.Lang.Float{

        function initialize(){
            Float.initialize();
        }

        /*
            Converts a float to ENDIAN_BIG style format.
            See https://www.h-schmidt.net/FloatConverter/IEEE754.html for example.
            
        */
        static function doubleToByteArray(input as Toybox.Lang.Double) as Toybox.Lang.ByteArray {
            if(!(input instanceof Toybox.Lang.Double) ){
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Double argument type",null,null);
            }

            if( input == 0d){
                // special separate case, because the exponent is set to zero
                return [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b;
            }

            var BITS_IN_MANTISSA = BytePacking.BITS_IN_DOUBLE_MANTISSA;
            var MINIMAL_EXPONENT = BytePacking.MINIMAL_DOUBLE_EXPONENT;
            var EXPONENT_BIAS = BytePacking.DOUBLE_EXPONENT_BIAS;
            var BITS_IN_EXPONENT = BytePacking.BITS_IN_DOUBLE_EXPONENT;
            var PARSING_SHIFT = 0;

            return BytePacking.BPFloat.genericToByteArray(input,BITS_IN_MANTISSA,MINIMAL_EXPONENT,EXPONENT_BIAS,BITS_IN_EXPONENT,PARSING_SHIFT);
            
        }
    }
}