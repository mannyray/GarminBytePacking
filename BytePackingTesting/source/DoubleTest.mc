using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePackingTesting{
   

    (:test)
    function DoubleTest_basic(logger as Toybox.Test.Logger) as Boolean {

        // used https://www.binaryconvert.com/result_double.html

        var testInputs = [
            {
                :input=>1.31050473727535029013015307522e-199d,
                :expectedArr=>[0x16,0xA4,0x10,0x02,0x01,0x11,0x24,0x20]b,
            },
            {
                :input=>4.41958748050657093439978681258e263d,
                :expectedArr=>[0x76,0xAC,0x12,0x23,0x01,0x31,0x24,0x26]b,
            },
            {
                :input=>4.87728005191958785057067871094e8d,
                :expectedArr=>[0x41,0xBD,0x12,0x23,0x85,0x31,0x24,0x36]b,
            },
            {
                :input=>-1.16183573193898954669148418496e-311d,
                :expectedArr=>[0x80,0x00,0x02,0x23,0x85,0x31,0x24,0x36]b,
            },
            {
                :input=>0d,
                :expectedArr=> [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]b,
            },
        ];

        for(var i=0; i<testInputs.size(); i++){
            System.println("Test case "+i);
            var compArr = BytePacking.BPDouble.doubleToByteArray(testInputs[i][:input]);
            assertEquivalencyBetweenByteArraysDouble(compArr,testInputs[i][:expectedArr]);
            Test.assertEqual(testInputs[i][:input],BytePacking.BPDouble.byteArrayToDouble(compArr));
        }
        return true;
    }
}