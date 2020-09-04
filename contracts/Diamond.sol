// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;
pragma experimental ABIEncoderV2;
/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of an ERC20 governance token that can govern itself and a project
* using the Diamond Standard.
/******************************************************************************/

import * as util from './libraries/Util.sol';
import * as gsf from './storage/GovernanceStorage.sol';
import * as qssf from './storage/QuickSwapStorage.sol';
import * as dsf from './storage/DiamondStorage.sol';
import { DiamondCutLib } from './libraries/DiamondCutLib.sol';
import { IDiamondLoupe } from './interfaces/IDiamondLoupe.sol';
import { IERC165 } from './interfaces/IERC165.sol';
import { DiamondLoupe } from './facets/DiamondLoupe.sol';
import { Governance } from './facets/Governance.sol';
import { QuickSwapToken } from './facets/QuickSwapToken.sol';
import { QuickSwapFactory } from './facets/QuickSwapFactory.sol';


contract Diamond {  
    
    constructor() {        
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        // Set total supply cap. The token supply cannot grow past this.
        gs.totalSupplyCap = 100_000_000e18;
        // Require 2 percent of governance token for votes to pass a proposal
        gs.quorumDivisor = 50;
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

        // QuickSwap variables
        qssf.QuickSwapStorage storage qss = qssf.quickSwapStorage();
        qss.feeToSetter = address(this);
        qss.feeTo = address(this);

        // Create a DiamondLoupeFacet contract which implements the Diamond Loupe interface
        DiamondLoupe diamondLoupe = new DiamondLoupe();   
        QuickSwapToken quickSwapToken = new QuickSwapToken();
        Governance governance = new Governance();
        QuickSwapFactory quickSwapFactory = new QuickSwapFactory();

        bytes[] memory cut = new bytes[](4);
        
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
            quickSwapToken,
            QuickSwapToken.name.selector,
            QuickSwapToken.symbol.selector,
            QuickSwapToken.decimals.selector,
            QuickSwapToken.totalSupply.selector,
            QuickSwapToken.balanceOf.selector,
            QuickSwapToken.transfer.selector,
            QuickSwapToken.transferFrom.selector,
            QuickSwapToken.approve.selector,
            QuickSwapToken.allowance.selector,
            QuickSwapToken.increaseAllowance.selector,
            QuickSwapToken.decreaseAllowance.selector
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

        cut[3] = abi.encodePacked(
            quickSwapFactory,
            QuickSwapFactory.allPairsLength.selector,
            QuickSwapFactory.feeTo.selector,
            QuickSwapFactory.feeToSetter.selector,
            QuickSwapFactory.getPair.selector,
            QuickSwapFactory.allPairs.selector,
            QuickSwapFactory.createPair.selector,
            QuickSwapFactory.setFeeTo.selector,
            QuickSwapFactory.setFeeToSetter.selector
        );

        
        DiamondCutLib.diamondCut(cut);
        
        // adding ERC165 data
        dsf.DiamondStorage storage ds = dsf.diamondStorage();
        ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;        
        bytes4 interfaceID = IDiamondLoupe.facets.selector ^ IDiamondLoupe.facetFunctionSelectors.selector ^ IDiamondLoupe.facetAddresses.selector ^ IDiamondLoupe.facetAddress.selector;
        ds.supportedInterfaces[interfaceID] = true;
    }  

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {        
        dsf.DiamondStorage storage ds;
        bytes32 position = keccak256("diamond.standard.diamond.storage");
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
  