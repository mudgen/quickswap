// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;

import { IERC20 } from '../interfaces/IERC20.sol';
import * as util from '../libraries/Util.sol';
import * as gsf from '../storage/GovernanceStorage.sol';

contract QuickSwapToken is IERC20 {   

    function name() public pure override returns (string memory) { return 'QuickSwap'; }

    function symbol() public pure override returns (string memory) { return 'QS'; }

    function decimals() public pure override returns (uint8) { return 18; }
    
    function totalSupply() external view override returns (uint) {        
        return gsf.governanceStorage().totalSupply;
    }

    function balanceOf(address _owner) external view override returns (uint balance) {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        balance = gs.balances[_owner];
    }

    function transfer(address _to, uint _value) external override returns (bool success) {
        _transferFrom(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(address _from, address _to, uint _value) external override returns (bool success) {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        uint allow = gs.approved[_from][msg.sender];
        require(allow >= _value || msg.sender == _from, 'ERC20: Not authorized to transfer');
        _transferFrom(_from, _to, _value);
        if(msg.sender != _from && allow != uint(-1)) {
            allow -= _value; 
            gs.approved[_from][msg.sender] = allow;
            emit Approval(_from, msg.sender, allow);
        }
        success = true;        
    }

    function _transferFrom(address _from, address _to, uint _value) internal {        
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        uint balance = gs.balances[_from];
        require(_value <= balance, 'ERC20: Balance less than transfer amount');
        gs.balances[_from] = balance - _value;
        gs.balances[_to] += _value;
        emit Transfer(_from, _to, _value);

        uint24[] storage proposalIds = gs.votedProposalIds[_from];
        uint index = proposalIds.length;
        while(index > 0) {
            index--;
            gsf.Proposal storage proposalStorage = gs.proposals[proposalIds[index]];
            require(block.timestamp > proposalStorage.endTime, 'ERC20Token: Can\'t transfer during vote');
            require(msg.sender != proposalStorage.proposer || proposalStorage.executed, 'ERC20Token: Proposal must execute first.');
            proposalIds.pop();
        }
    }

    function approve(address _spender, uint _value) external override returns (bool success) {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        gs.approved[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint remaining) {
        remaining = gsf.governanceStorage().approved[_owner][_spender];
    }

    function increaseAllowance(address _spender, uint _value) external returns (bool success) {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        uint allow = gs.approved[msg.sender][_spender];
        uint newAllow = allow + _value;
        require(newAllow > allow || _value == 0, 'Integer Overflow');
        gs.approved[msg.sender][_spender] = newAllow;
        emit Approval(msg.sender, _spender, newAllow);
        success = true;
    }

    function decreaseAllowance(address _spender, uint _value) external returns (bool success) {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        uint allow = gs.approved[msg.sender][_spender];
        uint newAllow = allow - _value;
        require(newAllow < allow || _value == 0, 'Integer Underflow');
        gs.approved[msg.sender][_spender] = newAllow;
        emit Approval(msg.sender, _spender, newAllow);
        success = true;
    }   
}