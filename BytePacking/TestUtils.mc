using Toybox.Test as Test;
import Toybox.System;
import Toybox.Lang;

module BytePacking{
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

    function assertEquivalencyBetweenByteArrays(arr1 as Toybox.Lang.ByteArray,arr2 as Toybox.Lang.ByteArray){
        Test.assertEqual(arr1.size(),arr2.size());
        for(var i=0; i<arr1.size(); i++){
            Test.assertEqualMessage(arr1[i],arr2[i],byteArrayToHexArrayString(arr1) + " versus " + byteArrayToHexArrayString(arr2));
        }
    }
}