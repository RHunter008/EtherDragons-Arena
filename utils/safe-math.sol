pragma solidity ^0.4.0;

 // @title SafeMath256
 // @dev Math operations with safety checks that throw on error
library SafeMath256 {

  // @dev Multiplies two numbers, throws on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  // @dev Integer division of two numbers, truncating the ratio.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }


  // @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  // @dev Adds two numbers, throws on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library SafeMath32 {
  // @dev Multiplies two numbers, throws on overflow.
  function mul(uint32 a, uint32 b) internal pure returns (uint32 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }


  // @dev Integer division of two numbers, truncating the ratio.
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }


  // @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }


  // @dev Adds two numbers, throws on overflow.
  function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library SafeMath8 {
  // @dev Multiplies two numbers, throws on overflow.
  function mul(uint8 a, uint8 b) internal pure returns (uint8 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }


  // @dev Integer division of two numbers, truncating the ratio.
  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint8 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }


  // @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }


  // @dev Adds two numbers, throws on overflow.
  function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
