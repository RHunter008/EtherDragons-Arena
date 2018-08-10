pragma solidity ^0.4.11;

 // @title String utils
 // @dev String functions for carefull operations 
 library StringUtils {
    function concat(string _a, string _b)
        internal
        pure
        returns (string)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);

        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
}

library UintStringUtils {
    function toString(uint i)
        internal
        pure
        returns (string)
    {
        if (i == 0) return '0';
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}
