// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { IERC20 } from '../interfaces/IERC20.sol';
import { InternalFunctions } from '../libraries/InternalFunctions.sol';

contract ERC20Token is IERC20, InternalFunctions {   

    function name() public pure override returns (string memory) { return 'GovernanceToken'; }

    function symbol() public pure override returns (string memory) { return 'GT'; }

    function decimals() public pure override returns (uint8) { return 18; }
    
    function totalSupply() external view override returns (uint) {        
        return erc20TokenStorage().totalSupply;
    }

    function balanceOf(address _owner) external view override returns (uint balance) {
        ERC20TokenStorage storage gts = erc20TokenStorage();
        balance = gts.balances[_owner];
    }

    function transfer(address _to, uint _value) external override returns (bool success) {
        _transferFrom(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(address _from, address _to, uint _value) external override returns (bool success) {
        ERC20TokenStorage storage gts = erc20TokenStorage();
        uint allow = gts.approved[_from][msg.sender];
        require(allow >= _value || msg.sender == _from, 'ERC20: Not authorized to transfer');
        _transferFrom(_from, _to, _value);
        if(msg.sender != _from && allow != uint(-1)) {
            allow -= _value; 
            gts.approved[_from][msg.sender] = allow;
            emit Approval(_from, msg.sender, allow);
        }
        success = true;        
    }

    function _transferFrom(address _from, address _to, uint _value) internal {
        (ERC20TokenStorage storage gts,
         GovernanceStorage storage gs) = governanceTokenStorage();
        uint balance = gts.balances[_from];
        require(_value <= balance, 'ERC20: Balance less than transfer amount');
        gts.balances[_from] = balance - _value;
        gts.balances[_to] += _value;
        emit Transfer(_from, _to, _value);

        uint24[] storage proposalIds = gs.votedProposalIds[_from];
        uint index = proposalIds.length;
        while(index > 0) {
            index--;
            Proposal storage proposalStorage = gs.proposals[proposalIds[index]];
            require(block.timestamp > proposalStorage.endTime, 'ERC20Token: Can\'t transfer during vote');
            require(msg.sender != proposalStorage.proposer || proposalStorage.executed, 'ERC20Token: Proposal must execute first.');
            proposalIds.pop();
        }
    }

    function approve(address _spender, uint _value) external override returns (bool success) {
        ERC20TokenStorage storage gts = erc20TokenStorage();
        gts.approved[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint remaining) {
        remaining = erc20TokenStorage().approved[_owner][_spender];
    }

    function increaseAllowance(address _spender, uint _value) external returns (bool success) {
        ERC20TokenStorage storage gts = erc20TokenStorage();
        uint allow = gts.approved[msg.sender][_spender];
        uint newAllow = allow + _value;
        require(newAllow > allow || _value == 0, 'Integer Overflow');
        gts.approved[msg.sender][_spender] = newAllow;
        emit Approval(msg.sender, _spender, newAllow);
        success = true;
    }

    function decreaseAllowance(address _spender, uint _value) external returns (bool success) {
        ERC20TokenStorage storage gts = erc20TokenStorage();
        uint allow = gts.approved[msg.sender][_spender];
        uint newAllow = allow - _value;
        require(newAllow < allow || _value == 0, 'Integer Underflow');
        gts.approved[msg.sender][_spender] = newAllow;
        emit Approval(msg.sender, _spender, newAllow);
        success = true;
    }   
}