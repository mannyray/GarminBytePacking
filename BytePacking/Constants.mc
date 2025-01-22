import Toybox.Lang;

module BytePacking{
    const BYTE_SIZE as Number = 8;
    const BITS_IN_FLOAT as Number = 32;
    const BITS_IN_LONG as Number = 64;
    const BYTES_IN_FLOAT as Number = BITS_IN_FLOAT/BYTE_SIZE;
    const BYTES_IN_LONG as Number = BITS_IN_LONG/BYTE_SIZE;
}