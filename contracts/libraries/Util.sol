// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;
pragma experimental ABIEncoderV2;

import * as gsf from '../storage/GovernanceStorage.sol';


function mintGovernanceTokens(address _to, uint _value) {
    gsf.GovernanceStorage storage gs = gsf.governanceStorage();
    uint totalSupply = gs.totalSupply;
    uint totalSupplyCap = gs.totalSupplyCap;
    if(totalSupply < totalSupplyCap) {        
        uint diff = totalSupplyCap - totalSupply;
        if(_value > diff) {
            _value = diff;
        }
        if(_value > 0) {    
            gs.totalSupply += uint96(_value);
            gs.balances[_to] += _value;
        }
    }
}

