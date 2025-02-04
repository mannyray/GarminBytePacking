import Toybox.Lang;

module BytePacking{
    const BYTE_SIZE as Number = 8;
    const BITS_IN_FLOAT as Number = 32;
    const BITS_IN_LONG as Number = 64;
    const BYTES_IN_FLOAT as Number = BITS_IN_FLOAT/BYTE_SIZE;
    const BYTES_IN_LONG as Number = BITS_IN_LONG/BYTE_SIZE;


    const BITS_IN_FLOAT_MANTISSA = 23;
    const BITS_IN_DOUBLE_MANTISSA = 52;
    const MINIMAL_FLOAT_EXPONENT = -127;
    const MINIMAL_DOUBLE_EXPONENT = -1023;
    const FLOAT_EXPONENT_BIAS = 127;
    const DOUBLE_EXPONENT_BIAS = 1023;
    const BITS_IN_FLOAT_EXPONENT = 8;
    const BITS_IN_DOUBLE_EXPONENT = 11;

    const SHIFT_DUE_TO_FLOAT=32;

    const LEADING_ONE_OUTSIDE_MANTISSA_BIT = 1;
    const BITS_IN_SIGN = 1;
    const FLOAT_ALL_ONES_EXPONENT = 255;
}