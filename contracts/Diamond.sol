// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of an ERC20 governance token that can govern itself and a project
* using the Diamond Standard.
/******************************************************************************/

import { InternalFunctions } from './libraries/InternalFunctions.sol';
import { IDiamondLoupe } from './interfaces/IDiamondLoupe.sol';
import { IERC165 } from './interfaces/IERC165.sol';
import { DiamondLoupe } from './facets/DiamondLoupe.sol';
import { Diamond, DiamondStorageContract } from './libraries/Diamond.sol';
import { ERC20Token } from './facets/ERC20Token.sol';
import { Governance } from './facets/Governance.sol';

contract GovernanceTokenDiamond is InternalFunctions {  
    
    constructor() {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();
        // Set total supply cap. The token supply cannot grow past this.
        ets.totalSupplyCap = 100_000_000e18;
        // Require 5 percent of governance token for votes to pass a proposal
        gs.quorumDivisor = 20;
        // Proposers must own 1 percent of totalSupply to submit a proposal
        gs.proposalThresholdDivisor = 100;
        // Proposers get an additional 5 percent of their balance if their proposal passes
        gs.proposerAwardDivisor = 20;
        // Voters get an additional 1 percent of their balance for voting on a proposal
        gs.voterAwardDivisor = 100;
        // Cap voter and proposer balance used to generate awards at 5 percent of totalSupply
        // This is to help prevent too much inflation
        gs.voteAwardCapDivisor = 20;
        // Proposals must have at least 48 hours of voting time
        gs.minimumVotingTime = 48;
        // Proposals must have no more than 336 hours (14 days) of voting time
        gs.maximumVotingTime = 336;

        // Create a DiamondLoupeFacet contract which implements the Diamond Loupe interface
        DiamondLoupe diamondLoupe = new DiamondLoupe();   
        ERC20Token erc20Token = new ERC20Token();
        Governance governance = new Governance();

        bytes[] memory cut = new bytes[](3);
        
        // Adding diamond loupe functions                
        cut[0] = abi.encodePacked(
            diamondLoupe,
            IDiamondLoupe.facetFunctionSelectors.selector,
            IDiamondLoupe.facets.selector,
            IDiamondLoupe.facetAddress.selector,
            IDiamondLoupe.facetAddresses.selector,
            IERC165.supportsInterface.selector            
        );

        cut[1] = abi.encodePacked(
            erc20Token,
            ERC20Token.name.selector,
            ERC20Token.symbol.selector,
            ERC20Token.decimals.selector,
            ERC20Token.totalSupply.selector,
            ERC20Token.balanceOf.selector,
            ERC20Token.transfer.selector,
            ERC20Token.transferFrom.selector,
            ERC20Token.approve.selector,
            ERC20Token.allowance.selector,
            ERC20Token.increaseAllowance.selector,
            ERC20Token.decreaseAllowance.selector
        );

        cut[2] = abi.encodePacked(
            governance,
            Governance.propose.selector,
            Governance.executeProposal.selector,
            Governance.proposalStatus.selector,
            Governance.proposal.selector,
            Governance.vote.selector,
            Governance.unvote.selector
        );
        
        diamondCut(cut);
        
        // adding ERC165 data
        DiamondStorage storage ds = diamondStorage();
        ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;        
        bytes4 interfaceID = IDiamondLoupe.facets.selector ^ IDiamondLoupe.facetFunctionSelectors.selector ^ IDiamondLoupe.facetAddresses.selector ^ IDiamondLoupe.facetAddress.selector;
        ds.supportedInterfaces[interfaceID] = true;
    }  

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {        
        DiamondStorage storage ds;
        bytes32 position = DiamondStorageContract.DIAMOND_STORAGE_POSITION;           
        assembly { ds.slot := position }
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Function does not exist.");
        assembly {
            let ptr := 0
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), facet, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }

    receive() external payable {
    }
}
  