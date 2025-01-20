import Toybox.System;


module BytePacking{

    /*
        Class used for determining and storing how many bits are required
        to store a long.
    */
    class BinaryDataPair { //TODO: of long, of decimal methods? some sort of private constructor approach with static methods?
        var long as Toybox.Lang.Long;
        var bitCount as Toybox.Lang.Number;
        function initialize(input as Toybox.Lang.Long){

            if(!(input instanceof Toybox.Lang.Long) ){
                /*
                    Necessary, as even though function header specified "as Toybox.Lang.Long",
                    user can input a Number type which will result in
                    incorrect/illogical behaviour even though the function does not crash.
                */
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Long argument type",null,null);
            }

            if(input < 0){
                /*
                    the top most bit, in a long, is reserved for the sign bit. We don't want that sign bit
                    impacting the total bitCount required to store the long. The additional +1 bit for the sign
                    can be kept track by the user, separately, outside of this class.
                */
                throw new Toybox.Lang.InvalidValueException("Expecting a non negative long");
            }

            long = input;
            var inputCopy = input;
            bitCount = 0;
            while(inputCopy > 0){
                /*
                    keep shifting the binary version of the number to the right until all the
                    digits are zero at which point we have counted all the bits
                    required to represent this number
                */
                inputCopy = inputCopy >> 1;
                bitCount++;
            }
        }
    }

    /*
        TODO: explanation 
        TODO: if code is generic enough then you can test it on floats first  https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ByteArray.html#encodeNumber-instance_function
    */
    function getBitsOfDecimal(input as Toybox.Lang.Double, maximumBits as Toybox.Lang.Number) as BinaryDataPair{
        
        if(!(input instanceof Toybox.Lang.Double) ){
            /*
                Necessary, to avoid unexpected behaviour if user supplies a Number for example.
            */
            throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Double argument type",null,null);
        }

        if(input < 0 or input >= 1){
            /*
            We expect input of the type 0.123... . The caller must themselves format the double to remove
            the leading number (e.g. var double = 1.123; var input = double - decimal.toLong(); )
            */
            throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Double in the range of (0,1)");
        }

        var longBitVersion = 0l;// TODO: explain
        var output = new BinaryDataPair(longBitVersion);

        var one = 1l;//in binary has only the last, rightmost, bit as binary "1"
        var inputCopy = input;

        while(inputCopy != 0 and output.bitCount < maximumBits){
            //TODO concatenate?
            
            longBitVersion = longBitVersion<<1;//TODO:

            inputCopy = inputCopy*2;

            if(inputCopy >= 1){
                longBitVersion = longBitVersion | one;
                inputCopy = inputCopy - inputCopy.toNumber();//TODO: explain
            }

            
            output.bitCount++;
        }
        output.long = longBitVersion;

        return output;
    }

    function getDecimalOfBits( input as BinaryDataPair) as Toybox.Lang.Double {
        return 0d;
    }

}