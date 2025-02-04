import Toybox.System;
import Toybox.Math;


module BytePacking{

    /*
        Class used for determining and storing how many bits are required
        to store a long.

        Example: 50l ("l" to mean its a long number and not a regular number in monkey c notation)
        is represented as "110010" which means the number requires 6 bits to store.
    */
    class BinaryDataPair {
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
        Class used for determining and storing how many bits are required
        to store the positive integer portion of a double.

        Example: -4936.120 has the positive integer portion as 4936
        which can be stored as 1001101001000

        Therefore, the totalBitCount is 13, while bitCountBeforeAllZeros is 10
        for the 1001101001 portion before the three trailing zeros in 1001101001000.

        The long member of FloorData stores the portion before all zeros 1001101001 which represents 617. 

        The reason we track all the trailing zeros and compact the number 4936 to 617 (with the knowledge of bitCountBeforeAllZeros being 3  )
        is because of the following example:

        Consider the double 1.7014118e38 which is equivalent to 2^{127} which in regular binary is a "1", followed by 126 binary zeros.
        While this number can be compactly stored in float/double's IEEE 754 format easily, (01111111000000000000000000000000 according to https://www.h-schmidt.net/FloatConverter/IEEE754.html),
        requiring 32 bits, long can only store a maximum number of 2,147,483,647 ( way less than 2^{127}) as it uses regular binary format. However,
        we can store long member of FloorData as decimal "1" (equivalent to binary "1") while setting bitCountBeforeAllZeros to be 1.

        Therefore, we can convert all positive integer portions of a double to FloorData format as the maximum bits in a long is 64 while the mantissa portion in a double
        is 52 bits.
    */
    class FloorData{
        private var _long as Toybox.Lang.Long;
        private var _totalBitCount as Toybox.Lang.Number;
        private var _bitCountBeforeAllZeros as Toybox.Lang.Number;
        private function initialize(l as Toybox.Lang.Long, lbc as Toybox.Lang.Number, bcbaz as Toybox.Lang.Number){
            _totalBitCount = lbc;
            _long = l;
            _bitCountBeforeAllZeros = bcbaz;
        }

        function getLongEquivalent() as Toybox.Lang.Long{
            return _long;
        }

        function getTotalBitCount() as Toybox.Lang.Number{
            return _totalBitCount;
        }

        function getBitCountBeforeTrailingZeros() as Toybox.Lang.Number{
            return _bitCountBeforeAllZeros;
        }

        function getTrailingZeroCount() as Toybox.Lang.Number{
            return _totalBitCount - _bitCountBeforeAllZeros;
        }

        function removeLeadingBit() as Void{
            /*
                Useful for when storing the number in the mantissa where the leading one
                binary is impicit.
            */
            _long = _long & longWithFirstNBitsZero(BITS_IN_LONG - _bitCountBeforeAllZeros+1);
            _bitCountBeforeAllZeros--;
            _totalBitCount--;
        }
        
        // see class description for details
        static function getBitsOfFloor(input as Toybox.Lang.Double) as FloorData {
            if(!(input instanceof Toybox.Lang.Double) ){ 
                /*
                    Necessary, to avoid unexpected behaviour if user supplies a Number for example.
                */
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Double argument type as argument",null,null);
            }
            if(isnan(input)){
                throw new Toybox.Lang.InvalidValueException("Toybox.Lang.Double input can't be a 'nan'");
            }
            if(isinf(input)){
                throw new Toybox.Lang.InvalidValueException("Toybox.Lang.Double input can't be a 'inf'");
            }
            if(Math.floor(input) - input != 0 ){
                throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Double without anything after the '.'");
            }
            if(input < 0 ){
                throw new Toybox.Lang.InvalidValueException("Expecting a greater than zero Toybox.Lang.Double");
            }

            var totalBitCountInNumber = 0;
            var inputCopy = input;
            var bitCountBeforeAllZeros = 0;
            var longEquivalent = 0l;
            var firstOne = longWithFirstNBitsOne(1);
            var firstZero = longWithFirstNBitsZero(1);
            
            /*
                We keep diving the integer over and over thus "shifting" its bits to the right each time.
                For example 1011.0 binary (in decimal equal to 11) divided by two gives
                101.1 where the .1 or (in decimal equal to 0.5) the remainder means that we have just crossed a 
                "1" binary across the "." (otherwise we crossed a "0" binary). By keep tracking of which binary crossed the
                "." with each division we can copy over the bits to longEquivalent as we divide the integer all the way to zero.

                Since we are discovering the number's bits starting from the right hand side then we append the bits one by one to the 
                longEquivalent copy one by one on the left side and shift over to the right each time we discover a new bit. The result will be
                the bits of the original double all on the left hand side of longEquivalent, which we correwct at the end of the while loop by right shifting
                to the end.

                Code here similar in spirit to getBitsOfDecimal expect now we divide instead of multiply
            */
            while(inputCopy != 0){
                inputCopy = inputCopy / 2d;
                var remainder = inputCopy - Math.floor(inputCopy);

                longEquivalent = longEquivalent >> 1;
                /*
                    We overwrite the new leading bit to zero for the default case in case binary 0 crossed the ".". 
                    We cannot assuming the >>1 operation will provide a leading zero bit (especially in the case if the previous leading bit was "1")
                */
                longEquivalent = firstZero & longEquivalent;

                if(bitCountBeforeAllZeros>0){
                    bitCountBeforeAllZeros++;
                }
                
                if(remainder > 0){
                    inputCopy = inputCopy - remainder;// we don't care to track the crossed binary over the "." once tracked so we remove it
                    longEquivalent = longEquivalent | firstOne;//since remainder>0 then a binary 1 has crossed the "."
                    if(bitCountBeforeAllZeros==0){ // to track the very first binary 1 crossing the "." to give us the total amount of bits before all the zeros
                        bitCountBeforeAllZeros++;
                    }
                }
                totalBitCountInNumber++;
            }

            // following two lines are clearing out the sign bit which is the leading bit in the long number format
            longEquivalent = longEquivalent >> 1;
            longEquivalent = longEquivalent & firstZero;

            // right shift all the way as described before the while loop
            longEquivalent = longEquivalent >> ( BytePacking.BITS_IN_LONG - bitCountBeforeAllZeros -1 );
            return new FloorData(longEquivalent, totalBitCountInNumber, bitCountBeforeAllZeros);
        }


        static function newFloorData(long as Toybox.Lang.Long, totalBitCount as Toybox.Lang.Number) as FloorData{
            /*
                Create a FloorData object for the case when there is an expected amount totalBitCount as well as
                a long input that may or not have already some of the trailing zeros as part of _bitCountBeforeAllZeros

                Objective: compute the real value of _bitCountBeforeAllZeros based on totalBitCount and already 
                present trailing zeros in long as well as set the long as that its bits purely represent the part before all the zeros

                Example:
                Binary
                Input: 100100 ( long = 36 decimal) and totalBitCount 10
                Output: FloorData(_long=9('1001'), _totalBitCount=10, _bitCountBeforeAllZeros=4)
            */

            if(!(long instanceof Toybox.Lang.Long) ){
                /*
                    Necessary, to avoid unexpected behaviour if user supplies a Number for example.
                */
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Long argument type as first argument",null,null);
            }
            if(long <= 0){
                throw new Toybox.Lang.InvalidValueException("Expected positive integer Toybox.Lang.Long as first argument");
            }

            // we keep shifting our long to the right until we have removed all the trailing zeros (e.g. fro 100100 -> 1001)
            var onlyRightmostBitOne = 1l;
            var firstBit = long & onlyRightmostBitOne;
            while(firstBit!=1l){
                long = long >> 1;
                firstBit = long & onlyRightmostBitOne;
            }

            // now we have removed the trailing zeros so time to determine bit count of this new long
            var bdp = new BinaryDataPair(long); 
            if (totalBitCount < bdp.bitCount){
                throw new Toybox.Lang.InvalidValueException("totalBitCount illogical");
            }
            // totalBitCount remains the same as we assume the caller provided the right value
            return new FloorData(long, totalBitCount, bdp.bitCount);
        }

        /*
            This function does the reverse of getBitsOfFloor
        */
        function getFloorOfBits() as Toybox.Lang.Double{
            /*
                We assume that newFloorData has cleaned up trailing zeros. We test for this.
                If it has not then it is not true to FloorData's defitions of
                _long, _totalBitCount, _bitCountBeforeAllZeros and so our algorithm below might
                be broken
            */
            var testFloorData = newFloorData(_long,_totalBitCount);
            if(_long!= testFloorData.getLongEquivalent() or _bitCountBeforeAllZeros != testFloorData.getBitCountBeforeTrailingZeros() ){
                throw new Toybox.Lang.InvalidValueException("There are still trailing zeros in "+_bitCountBeforeAllZeros + " "+testFloorData.getBitCountBeforeTrailingZeros());
            }

            var output = 0d;
            var multipyingFactor = 1d;
            var onlyRightmostBitOne = 1l;
            var longCopy = _long;

            /*
                Starting with the right most binary digits of the long
                we add them to our output sum of the individual digits
                that are multiplied by multipyingFactor. multipyingFactor
                grows from 1 by a power of 2 each time because as we go from right
                most to left most binary digits the order grows by 2 each digit
            */
            for(var i=0; i<_bitCountBeforeAllZeros; i++){
                output = output + (longCopy&onlyRightmostBitOne).toDouble() * multipyingFactor;//(longCopy&onlyRightmostBitOne).toDouble() extracts the right most digit (1 or 0)
                longCopy = longCopy >> 1;//remove the right most digit, for the next one to be processed
                multipyingFactor *= 2d;
            }

            /*
                For the trailing zeros binary bits its equivalent to just multipying by two a bunch of times

                e.g. Difference between 100100 (36) and 1001 (9) is the two trailing zeros of the former account for *2^2 effect
            */
            for(var i=0; i< getTrailingZeroCount(); i++){
                output = output * 2d;
            }
            return output;
        }
    }

    class DecimalData{
        private var long as Toybox.Lang.Long;
        private var totalBitCount as Toybox.Lang.Number;
        private var bitCountAfterLeadingZeros as Toybox.Lang.Number;
        private function initialize(l as Toybox.Lang.Long, lbc as Toybox.Lang.Number, bcafo as Toybox.Lang.Number){
            long = l;
            totalBitCount = lbc;
            bitCountAfterLeadingZeros = bcafo;
        }

        static function newDecimalData(longInput as Toybox.Lang.Long, bitCountMax as Toybox.Lang.Number) as DecimalData{
            /*
                Create a DecimalData object from unclean input.

                For example: 
                Input is .0001000 or longInput=8 with bitCountMax set to 7
                The trailing three 0s are unecessary so the the following output should be
                long=1,totalBitCount=4,bitCountAfterLeadingZeros=1 
            */
            if(!(longInput instanceof Toybox.Lang.Long) ){
                /*
                    Necessary, to avoid unexpected behaviour if user supplies a Number for example.
                */
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Long argument type as first argument",null,null);
            }
            if(longInput < 0){
                throw new Toybox.Lang.InvalidValueException("Expecting a positive long input as first argument");
            }

            if(longInput == 0){
                return new DecimalData(0l,0,0);
            }

            /*
                we adjust the input longInput to remove the trailing zeros because in a binary decimal
                "0.0010", the last "0" doesn't effect the actual value. In addition, we adjust the totalBitCount
                to remove these from the count
            */
            var onlyRightmostBitOne = 1l;
            var firstBit = longInput & onlyRightmostBitOne;
            var trailingZeroCount = 0;
            while(firstBit!=1l){
                longInput = longInput >> 1;
                firstBit = longInput & onlyRightmostBitOne;
                trailingZeroCount++;
            }
            var totalBitCount = bitCountMax - trailingZeroCount;
            
            /*
                We compute bitCountAfterLeadingZeros (in the case of "0.001" it 1 for the "1")
            */
            var bdp = new BinaryDataPair(longInput);
            if(totalBitCount - bdp.bitCount < 0){
                /*
                    A basic sanity check. However, we can't catch all cases here
                    as totalBitCount is supposed to include the leading zeros but
                    that all depends on if the caller specifies that leading count correctly 
                    as part of totalBitCount as the code here has not way of determining if it is
                    actually correct (since the leading 0s are implicit).
                */
                throw new Toybox.Lang.InvalidValueException("bitCountMax illogical");
            }

            return new DecimalData(longInput, totalBitCount, bdp.bitCount);
        }

        function getLongEquivalent() as Toybox.Lang.Long{
            return long; 
        }

        function getTotalBitCount() as Toybox.Lang.Number{
            return totalBitCount;
        }

        function getBitCountAfterLeadingZeros() as Toybox.Lang.Number{
            return bitCountAfterLeadingZeros;
        }

        /*
            For a given Decimal number, say 0.1875, we return a Long representation of it along with the
            amount of binary bits required to store it. The equivalent of 0.1875 in "decimal" binary is
            "0.0011" (i.e. 0*2^{-1} + 0*2^{-2} + 1*2^{-3} + 1*2^{-4}= 0.1875). Observe how there are always 
            a set amount (0 or more) of leading binary zeros after the "." before the first binary "1" starts.
            
            In Long format, we can't store the leading two zeros so we say the long representation of this is the number 3 (of the binary 
            "11") while the leading two zero bits will implicit and encoded as part of the DecimalData object's
            totalBitCount which will be set to 4 in this instance (two for the first two zeros and two for the "11").
            We also store the value 2 for bitCountAfterLeadingZeros to show total bit count to store the number 3.

            optionDict allows us to specify one of two possible maximums:
            :maximumBits
            :maximumBitsAfterLeadingZeros
            The former is useful if we will expressing the leading zeros expicitly as part so therefore the amount of bits computed by
            getBitsOfDecimal will have to share those between the leading zeros and everything else that follows.
            The latter is useful if we do not have to express the leading zeros explicitly and can just worry about the tailing part
            of the binary.
        */
        static function getBitsOfDecimal(input as Toybox.Lang.Double, optionDict as Toybox.Lang.Dictionary) as DecimalData{
            
            if(!(input instanceof Toybox.Lang.Double) ){
                /*
                    Necessary, to avoid unexpected behaviour if user supplies a Number for example.
                */
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Double argument type as first argument",null,null);
            }

            if(input < 0 or input >= 1){
                /*
                We expect input of the type 0.123... . The caller must themselves format the double to remove
                the leading number (e.g. var double = 1.123; var input = double - decimal.toLong(); )
                */
                throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Double in the range of (0,1) as first argument");
            }

            if(!(optionDict instanceof Toybox.Lang.Dictionary)){
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Dictionary argument type as second argument",null,null);
            }
            if(!(   optionDict.size()==1 and (optionDict.hasKey(:maximumBits) or optionDict.hasKey(:maximumBitsAfterLeadingZeros)))   ){
                throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Dictionary of size of 1 with one of maximumBitsAfterLeadingZeros or maximumBits defined");
            }
            if(optionDict.hasKey(:maximumBits)){
                if(!(optionDict[:maximumBits] instanceof Toybox.Lang.Number and optionDict[:maximumBits] >= 0)){
                    throw new Toybox.Lang.InvalidValueException("maximumBits must be a Toybox.Lang.Number greater than or equal to zero");
                }
            }
            if(optionDict.hasKey(:maximumBitsAfterLeadingZeros)){
                if(!(optionDict[:maximumBitsAfterLeadingZeros] instanceof Toybox.Lang.Number and optionDict[:maximumBitsAfterLeadingZeros] >= 0)){
                    throw new Toybox.Lang.InvalidValueException("maximumBitsAfterLeadingZeros must be a Toybox.Lang.Number greater than or equal to zero");
                }
            }
            
            var dummyMaxValue = 10000000;
            var maximumBits = optionDict.hasKey(:maximumBits) ? optionDict[:maximumBits] : dummyMaxValue;
            var maximumBitsAfterLeadingZeros = optionDict.hasKey(:maximumBitsAfterLeadingZeros) ? optionDict[:maximumBitsAfterLeadingZeros] : dummyMaxValue;


            var totalBitCount = 0;
            var longEquivalent = 0l;
            var bitCountSinceLeadingZeros = 0;

            // in binary -  this has only the last, rightmost, bit as "1"
            var one = 1l;
            var inputCopy = input;

            while(inputCopy != 0){

                if(optionDict.hasKey(:maximumBits)){
                    if(totalBitCount>= maximumBits){
                        break;
                    }
                }

                if(optionDict.hasKey(:maximumBitsAfterLeadingZeros)){
                    if(bitCountSinceLeadingZeros>= maximumBitsAfterLeadingZeros){
                        break;
                    }
                }
                /*
                    Through this loop, we reduce the original decimal
                    to zero, by constantly doubling it and removing the 
                    integer portion of the number. Doubling has an effect
                    of shifting the bits, for example "0.001" in binary (in decimal is 0.125)
                    becomes "00.01" (in decimal 0.25) after doubling (the bits have shifted over the ".").
                    
                    In our loop, we track each bit that crosses the "." mark, after multipying,
                    in order to trascribe it over to our output.long . 
                    If it is a zero then we just shift over the bits in output.long
                    which has the equivalent effect of adding a tailing binary "0"
                    in output.long. If it is a one, then we still shift over, but also
                    logical OR a "1" bit to the tail.

                    We remove the integer portion of the number each loop in order for it to be clear
                    if the bit in the current iteration crossing the "." is a "1" or "0" bit.

                    Each loop, bitCount grows by one to keep tracking of the total amount of
                    bits required, including the first potential batch of "0" bits.
                */

                longEquivalent = longEquivalent<<1;

                inputCopy = inputCopy*2;

                if(bitCountSinceLeadingZeros > 0){
                    bitCountSinceLeadingZeros++;
                }

                if(inputCopy >= 1){
                    longEquivalent = longEquivalent | one;
                    inputCopy = inputCopy - inputCopy.toNumber();//toNumber rounds inputCopy to integer
                    if(bitCountSinceLeadingZeros == 0){
                        bitCountSinceLeadingZeros = 1;
                    }
                }
                totalBitCount++;
            }

            return new DecimalData(longEquivalent, totalBitCount, bitCountSinceLeadingZeros);
        }

        /*
            See getBitsOfDecimal header for details as this function is designed to be 
            the opposite of that.

            Input specification by example:
                    say input.long is 5 which in binary is "101"
                    while input.bitCount is 5 which means the 
                    binary "decimal" number is "0.00101" (we shift the the "101" 2 spots over to get 5 binary decimal spots)
                    which in decimal is 0.15625 according to
                    https://www.rapidtables.com/convert/number/binary-to-decimal.html?x=0.00101

                    our input stores the binary decimal as a long while the bitCount determines where the "." is located
                    long is favoured for storage as it is easy to use in bit manipulation.
            
            The code in this function returns the double version of a decimal encoded in BinaryDataPair format.
        */
        function getDecimalOfBits() as Toybox.Lang.Double {
            var longCopy = long;
            var output = 0d;
        
            while(longCopy > 0){
                /*
                    The code in the loop here is the opposite of the
                    code in the loop getBitsOfDecimal.

                    We keep bit shifting the longCopy over by one and
                    if the tail end bit is 1 then we add this as a integer
                    portion to the double and divide by two. Otherwise we just divide by two,
                    which in the double has the equivalent effect of bit shiffting the decimal bits
                    'deeper' to the right.
                */
                var isFirstBitOne = 1 == (1l & longCopy);

                if(isFirstBitOne){
                    output = output + 1;
                }

                output = output / 2;
                longCopy = longCopy >> 1;
            }

            /*
                See getBitsOfDecimal for details - this code here
                makes sure we do not miss the leading batch of zeros
                in the decimal binary
            */
            for(var i=0; i<totalBitCount - bitCountAfterLeadingZeros; i++){
                output = output / 2;
            }

            return output;
        }
    }

    /*
        Return a long where the first N bits are binary "1" and the rest are binary "0"
    */
    function longWithFirstNBitsOne(bitCount as Toybox.Lang.Number) as Toybox.Lang.Long{
        if(bitCount < 0 or bitCount > BITS_IN_LONG or !(bitCount instanceof Toybox.Lang.Number)){
            throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Number in the range of [0,64], but got "+bitCount);
        }

        var output = 0l;
        for(var i=0; i<bitCount; i++){
            output = output << 1;
            output = output + 1l;
        }
        output = output << (BITS_IN_LONG-bitCount);
        return output;
    }

    /*
        Return a long where the first N bits are binary "0" and the rest are binary "1"
    */
    function longWithFirstNBitsZero(bitCount as Toybox.Lang.Number) as Toybox.Lang.Long{
        if(bitCount < 0 or bitCount > BITS_IN_LONG or !(bitCount instanceof Toybox.Lang.Number)){
            throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Number in the range of [0,64], but got "+bitCount);
        }

        var output = 0l;
        for(var i=0; i<BITS_IN_LONG-bitCount; i++){
            output = output << 1;
            output = output + 1l;
        }
        return output;
    }


    // https://forums.garmin.com/developer/connect-iq/f/discussion/338071/testing-for-nan/1777041#1777041
    const FLT_MAX = 3.4028235e38f;
    const DBL_MAX = 1.7976931348623157e308d;

    function isnan(x as Toybox.Lang.Float or Toybox.Lang.Double) as Toybox.Lang.Boolean {
        return x != x;
    }

    function isinf(x as Toybox.Lang.Float or Toybox.Lang.Double) as Toybox.Lang.Boolean {
        if(x instanceof Toybox.Lang.Double){
            return (x < -DBL_MAX || DBL_MAX < x);
        }
        return (x < -FLT_MAX || FLT_MAX < x);
    }

}