using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePackingTesting{
    /*
        Common functions useful for running tests.
    */

    function byteArrayToHexArrayString(arr as Toybox.Lang.ByteArray) as String{
        var outputString = "[";
        for(var arrayIndex=0; arrayIndex<arr.size(); arrayIndex++){
            outputString = outputString + "0x" +arr[arrayIndex].format("%x") +",";
        }
        outputString = outputString + "]";
        return outputString;
    }

    function byteArrayToBinaryString(arr as Toybox.Lang.ByteArray, spacingArr as Toybox.Lang.Array<Toybox.Lang.Number>) as String{
        var outputString = "";
        for(var i=0; i<arr.size(); i++){
            outputString = outputString + byteToBinaryString(arr[i]);
        }
        if(spacingArr.size()>0){
            var firstIndex = 0;
            var spacedOutputString = "";
            for(var i=0;i<spacingArr.size();i++){
                spacedOutputString = spacedOutputString + outputString.substring(firstIndex,spacingArr[i]) + " ";
                firstIndex = spacingArr[i];
            }
            spacedOutputString = spacedOutputString + outputString.substring(firstIndex,null);
            return spacedOutputString;
        }
        return outputString;
    }

    function byteToBinaryString(b as Toybox.Lang.Number) as String{
        // from: https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ByteArray.html#toString-instance_function
        // "ByteArray objects are fixed size, numerically indexed, single dimensional, and take Numbers with a value >= -128 and <= 255 as members."
        // and from google:
        // "byte: The byte data type is an 8-bit signed two's complement integer. It has a minimum value of -128 and a maximum value of 127 (inclusive)."
        // so therefore assuming that here it is shifted and represtented as [0,255] instead of [-128,127]
        Test.assertMessage(b >= 0,"dealing with bytes in range of [0,255]");
        var outputString = "";
        var longEquivalent = b.toLong();
        var oneInFirstBite = 1l;
        for(var i=0; i<8; i++){ // 8 bits in a byte
            if((oneInFirstBite & longEquivalent) == 1l){
                outputString = outputString + "1";
            }
            else{
                outputString = outputString + "0";
            }
            longEquivalent = longEquivalent>>1;
        }
        var reverseString = "";
        for(var i = outputString.length()-1; i>=0; i--){
            //System.println(outputString.substring(i,i+1));
            reverseString = reverseString + outputString.substring(i,i+1); 
        }
        return reverseString;
    }

    function assertEquivalencyBetweenByteArraysFloat(arr1 as Toybox.Lang.ByteArray,arr2 as Toybox.Lang.ByteArray){
        Test.assertEqual(arr1.size(),arr2.size());
        for(var i=0; i<arr1.size(); i++){
            Test.assertEqualMessage(arr1[i],arr2[i],
            "\n"+byteArrayToHexArrayString(arr1) + "\nversus \n" + byteArrayToHexArrayString(arr2) + 
            "\nor\n"+byteArrayToBinaryString(arr1,[1,9]) + "\nversus \n" + byteArrayToBinaryString(arr2,[1,9]) 
            );
        }
    }

    function assertEquivalencyBetweenByteArrays(arr1 as Toybox.Lang.ByteArray,arr2 as Toybox.Lang.ByteArray){
        Test.assertEqual(arr1.size(),arr2.size());
        for(var i=0; i<arr1.size(); i++){
            Test.assertEqualMessage(arr1[i],arr2[i],
            "\n"+byteArrayToHexArrayString(arr1) + "\nversus \n" + byteArrayToHexArrayString(arr2) + 
            "\nor\n"+byteArrayToBinaryString(arr1,[]) + "\nversus \n" + byteArrayToBinaryString(arr2,[]) 
            );
        }
    }
}