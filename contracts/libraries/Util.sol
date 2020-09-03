// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;
pragma experimental ABIEncoderV2;

import * as gsf from '../storage/GovernanceStorage.sol';


function mintGovToken(address _to, uint96 _value) {
    gsf.GovernanceStorage storage gs = gsf.governanceStorage();        
    gs.totalSupply += _value;
    gs.balances[_to] += _value;
}

