// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract ERC20TokenStorageContract {           

    bytes32 internal constant ERC20TOKEN_STORAGE_POSITION = keccak256("governance.token.diamond.ERC20Token");
    
    struct ERC20TokenStorage {  
        mapping(address => uint) balances;      
        mapping(address => mapping(address => uint)) approved;        
        uint96 totalSupplyCap;      
        uint96 totalSupply;                
    }

    function erc20TokenStorage() internal pure returns(ERC20TokenStorage storage ds) {
        bytes32 position = ERC20TOKEN_STORAGE_POSITION;
        assembly { ds.slot := position }
    }    
}

