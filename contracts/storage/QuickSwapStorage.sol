// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;

struct QuickSwapStorage {
    address feeTo;
    address feeToSetter;
    mapping(address => mapping(address => address)) getPair;
    address[] allPairs;  
}

function quickSwapStorage() pure returns (QuickSwapStorage storage ds) {
    bytes32 position = keccak256("governance.token.diamond.ERC20Token");
    assembly { ds.slot := position }
}


