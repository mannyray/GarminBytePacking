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
        we can store long member of FloorData as decimal "1" (equivalent to binary "1") while setting bitCountBeforeAllZeros to be 126.

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
            //TODO: explain and test.
            //TODO: off by one, edge case
            //TODO: edge case of calling this multiple times not skipping the zero
            _long = _long & longWithFirstNBitsZero(BITS_IN_LONG - _bitCountBeforeAllZeros+1);
            _bitCountBeforeAllZeros--;
            _totalBitCount--;
        }
        
        static function getBitsOfFloor(input as Toybox.Lang.Double) as FloorData {
            // TODO: input handling
            if(!(input instanceof Toybox.Lang.Double) ){ // TODO: test
                /*
                    Necessary, to avoid unexpected behaviour if user supplies a Number for example.
                */
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Double argument type as argument",null,null);
            }
            if(Math.floor(input) - input != 0 ){
                throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Double without anything after the '.'");
            }
            if(input < 0 ){
                throw new Toybox.Lang.InvalidValueException("Expecting a greater than zero Toybox.Lang.Double");
            }

            var totalBitCountInNumber = 0;
            var inputCopy = input;
            var bitsSinceFirstOne = 0;// in a float or double will be limited by mantissa length
            var longEquivalent = 0l;
            var firstOne = longWithFirstNBitsOne(1);//'inverse' becase regular one has the just the last bit as 1 unlike here
            var firstZero = longWithFirstNBitsZero(1);
            
            while(inputCopy != 0){//TODO: add examples, explain how it is simliar but different to getBitsOfDecimal
                inputCopy = inputCopy / 2d;
                var remainder = inputCopy - Math.floor(inputCopy);
                longEquivalent  = longEquivalent >> 1;
                longEquivalent = firstZero & longEquivalent;//TODO: why otherwise a bug

                if(bitsSinceFirstOne>0){
                    bitsSinceFirstOne++;
                }
                
                if(remainder > 0){
                    inputCopy = inputCopy - remainder;
                    longEquivalent = longEquivalent | firstOne;
                    if(bitsSinceFirstOne==0){
                        bitsSinceFirstOne++;//bitsBeforeAllZeros
                    }
                }

                totalBitCountInNumber++;
            }
            // TODO: explanation via example

            longEquivalent = longEquivalent >> 1;
            longEquivalent = longEquivalent & firstZero;

            longEquivalent = longEquivalent >> ( BytePacking.BITS_IN_LONG - bitsSinceFirstOne -1 );
            return new FloorData(longEquivalent, totalBitCountInNumber, bitsSinceFirstOne);
        }
    }

    class DecimalData{
        private var long as Toybox.Lang.Long;
        private var totalBitCount as Toybox.Lang.Number;
        private var bitCountAfterFirstOne as Toybox.Lang.Number;
        private function initialize(l as Toybox.Lang.Long, lbc as Toybox.Lang.Number, bcafo as Toybox.Lang.Number){
            long = l;
            totalBitCount = lbc;
            bitCountAfterFirstOne = bcafo;
        }

        function getLongEquivalent() as Toybox.Lang.Long{
            return long; 
        }

        function getTotalBitCount() as Toybox.Lang.Number{
            return totalBitCount;
        }

        function getBitCountAfterFirstOne() as Toybox.Lang.Number{
            return bitCountAfterFirstOne;
        }

        /*
            For a given Decimal number, say 0.1875, we return a Long representation of it along with the
            amount of binary bits required to store it. The equivalent of 0.1875 in "decimal" binary is
            "0.0011" (i.e. 0*2^{-1} + 0*2^{-2} + 1*2^{-3} + 1*2^{-4}= 0.1875). In Long format, we can't store the first
            two zeros so we say the long representation of this is the number 3 (of the binary 
            "11") while the first two zero bits will implicit and encoded as part of the BinaryDataPair object's TODO:BinaryDataPair no longer used
            bitCount which will be set to 4 in this instance (two for the first two zeros and two for the "11").

            maximumBits is useful for us to restrict how many binary bits we want to compute as some binary 
            decimals may have infinite numbers or we may not care about the remainder bits after a certain level
            of resolution. - TODO: replace with optionDict
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

            // TODO make this a hidden function to verify the dictionary
            if(!(optionDict instanceof Toybox.Lang.Dictionary)){
                //TODO: test this
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Dictionary argument type as second argument",null,null);
            }

            if(!(optionDict instanceof Toybox.Lang.Dictionary)){
                //TODO: test this
                throw new Toybox.Lang.UnexpectedTypeException("Expecting Toybox.Lang.Dictionary argument type as second argument",null,null);
            }

            if(!(   optionDict.size()==1 and (optionDict.hasKey(:maximumBits) or optionDict.hasKey(:maximumBitsAfterFirstOne)))   ){
                //TODO: test this
                throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Dictionary of size of 1 with TODO" + optionDict);
            }

            if(optionDict.hasKey(:maximumBits)){
                // TODO: test this
                if(!(optionDict[:maximumBits] instanceof Toybox.Lang.Number and optionDict[:maximumBits] >= 0)){//TODO: upper limit?
                    throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Dictionary of size of 1 with TODO");
                }
            }

            if(optionDict.hasKey(:maximumBitsAfterFirstOne)){
                // TODO: test this
                if(!(optionDict[:maximumBitsAfterFirstOne] instanceof Toybox.Lang.Number and optionDict[:maximumBitsAfterFirstOne] >= 0)){//TODO: upper limit?
                    throw new Toybox.Lang.InvalidValueException("Expecting a Toybox.Lang.Dictionary of size of 1 with TODO");
                }
            }
            

            var maximumBits = optionDict.hasKey(:maximumBits) ? optionDict[:maximumBits] : 10000000; //TODO change this one more than option possible
            var maximumBitsAfterFirstOne = optionDict.hasKey(:maximumBitsAfterFirstOne) ? optionDict[:maximumBitsAfterFirstOne] : 10000000; //TODO change this one more than option possible
            //TODO ^ naming convention to be inclusive of the first one?

            //TODO: maximumBits has to be a dictionary which specifies which maximum we are using
            // only one maximum can be defined in the dict: maximumOverAllBits XOR maximumBitsAfterFirstOne
            // }

            var totalBitCount = 0;
            var longEquivalent = 0l;
            var bitCountSinceFirstOne = 0;

            // in binary -  this has only the last, rightmost, bit as "1"
            var one = 1l;
            var inputCopy = input;

            while(inputCopy != 0){

                if(optionDict.hasKey(:maximumBits)){
                    if(totalBitCount>= maximumBits){
                        break;
                    }
                }

                if(optionDict.hasKey(:maximumBitsAfterFirstOne)){
                    if(bitCountSinceFirstOne>= maximumBitsAfterFirstOne){
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

                if(bitCountSinceFirstOne > 0){
                    bitCountSinceFirstOne++;
                }

                if(inputCopy >= 1){
                    longEquivalent = longEquivalent | one;
                    inputCopy = inputCopy - inputCopy.toNumber();//toNumber rounds inputCopy to integer
                    if(bitCountSinceFirstOne == 0){
                        bitCountSinceFirstOne = 1;
                    }
                }
                totalBitCount++;
            }

            return new DecimalData(longEquivalent, totalBitCount, bitCountSinceFirstOne);
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
                var isFirstBitOne = 1 == (1l && longCopy);

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
            for(var i=0; i<totalBitCount - bitCountAfterFirstOne; i++){
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
}