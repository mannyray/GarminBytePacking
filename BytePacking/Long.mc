import Toybox.Lang;
import Toybox.System;

module BytePacking{
    /*
        Class for dealing with converting a long to its byte array representation and vice versa.
        
        Garmin does have methods that already can convert a byte array to a Number type (and vice versa):
        https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ByteArray.html#decodeNumber-instance_function
        However, those are restricted to number formats that are 32 bit max:
        https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang.html#NUMBER_FORMAT_FLOAT-const
        

        Inspiration for code from 
        https://forums.garmin.com/developer/connect-iq/f/discussion/223920/trying-to-pack-a-long-64-bit-signed-integer-with-bytes
    */
    class Long extends Toybox.Lang.Long{
        hidden const BYTE_SIZE as Number = 8;// TODO put this in some more global file?
        hidden const BITS_IN_LONG as Number = 64;
        hidden const BYTES_IN_LONG as Number = BITS_IN_LONG/BYTE_SIZE;

        /*
            Converts a long to a byte array of size 8 since long is 64 bits long.
            Ouput is big endian style
            (e.g.  binary "10" of the long is interpreted as decimal 2 and not decimal 1).
            Function should be static, because this class, that is extending Toybox.Lang.Long,
            has no access to Toybox.Lang.Long's internal class variables used to store the long value,
            but is not due to symbol not found runtime errors:
            https://forums.garmin.com/developer/connect-iq/i/bug-reports/compiler-bug-cannot-compile-classes-with-static-functions
        */
        function longToByteArray(input as Toybox.Lang.Long) as Toybox.Lang.ByteArray {

            if(!(input instanceof Toybox.Lang.Long) ){
                /*
                    Necessary, as even though function header specified "as Toybox.Lang.Long",
                    user can input a Number type which will result in
                    incorrect/illogical behaviour even though the function does not crash.
                */
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Long argument type",null,null);
            }

            var byteArray = new[BytePacking.Long.BYTES_IN_LONG]b;//b for byte data type

            for(var arrayIndex = 0; arrayIndex<BytePacking.Long.BYTES_IN_LONG; arrayIndex++){
                /*
                    offset moves the input long so many bits over 'to the right'
                    via the >> operator in order to bit-operator-AND 
                    it with 0xff to isolate a spefic byte. We start with
                    isolating the left most byte of the long which is why
                    when arrayIndex == 0, offset is 56 which denotes the first 
                    byte (from 0 to 8 bits)
                */
                var offset = BytePacking.Long.BITS_IN_LONG-BytePacking.Long.BYTE_SIZE*(arrayIndex+1);

                /*
                    the 0's are technically uncessary in 0x00000000000000ff,
                    but are left to emphasize that by ANDing with such a number
                    we only care about the right most byte (two hex letters are a byte).
                    
                    toNumber() is used as byteArray only takes Numbers with a value >= -128 and <= 255
                    according to https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ByteArray.html.
                    We convert the Long to a Number while the value remains the same.
                */
                byteArray[arrayIndex] = ( (input >> offset) & 0x00000000000000ff ).toNumber();
            }
            return byteArray;
        }

        /*
            Converts a byte array of size 8 to a long since long is 64 bits long.
            Ouput is big endian style
            (e.g.  binary "10" is interpreted as decimal 2 and not decimal 1).
            Function should be static, because this class, that is extending Toybox.Lang.Long,
            has no access to Toybox.Lang.Long's internal class variables used to store the long value,
            but is not due to symbol not found runtime errors:
            https://forums.garmin.com/developer/connect-iq/i/bug-reports/compiler-bug-cannot-compile-classes-with-static-functions
        */
        function byteArrayToLong(input as ByteArray) as Toybox.Lang.Long{
            if(input.size()!=BytePacking.Long.BYTES_IN_LONG){
                throw new Toybox.Lang.InvalidValueException(Toybox.Lang.format("Byte array should be of size 8 and not: $1$", [input.size()]));
            }

            // Here we do the reverse of what is done in "longToByteArray" function above.
            var output = 0l;
            for(var arrayIndex = 0; arrayIndex<input.size(); arrayIndex++){

                // for offset, same reasoning as in longToByteArray
                var offset = BytePacking.Long.BITS_IN_LONG-BytePacking.Long.BYTE_SIZE*(arrayIndex+1);

                /*
                    using logical OR operator (|), we can combine the various bytes together

                    We convert byte array's value to Long for the reverse reason as to why we convert to 
                    toNumber() in "longToByteArray" above.
                */
                output = output | ( input[arrayIndex].toLong()  << offset);
            }
            return output;
        }
    }
}