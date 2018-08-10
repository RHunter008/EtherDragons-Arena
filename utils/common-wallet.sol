pragma solidity ^0.4.0;


// @dev Interface for intercontract money transfer
interface CommonWallet {
    function receive() external payable;
}
