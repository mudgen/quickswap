// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract GovernanceStorageContract {           

    bytes32 internal constant GOVERNANCE_STORAGE_POSITION = keccak256("governance.token.diamond.governance");
    
    struct Voted {        
        uint96 votes;
        bool support;
    }
    
    struct Proposal {
        mapping(address => Voted) voted;
        address proposalContract;
        address proposer;
        uint64 endTime;
        bool executed;        
        bool stuck;
        uint96 againstVotes;
        uint96 forVotes;                             
    }   

    // How Divisors work:
    // To get a percentage of a number in Solidity we divide instead of multiply 
    // We get the number to divide to get a percentage of a number with this formula: 
    // divisor = 100 / percentage number
    // For example let's say we want 25 percent of the number 7808. 
    // First we need to get the divisor so we get it like this:  100 / 25 = 4
    // So the divisor is 4.  Now we divide 475 by 4 which is 1952
    // And that is the answer: 25 percent of 7808 is 1952.
    
    struct GovernanceStorage {        
        mapping(uint => Proposal) proposals;
        mapping(address => uint24[]) votedProposalIds;
        uint24 proposalCount;
        // Proposer must own enough tokens to submit a proposal
        uint8 proposalThresholdDivisor;
        // The minimum amount of time a proposal can be voted on. In hours. 
        uint16 minimumVotingTime;
        // The maximum amount of time a proposal can be voted on. In hours. 
        uint16 maximumVotingTime;
        // Require an amount of governance tokens for votes to pass a proposal
        uint8 quorumDivisor;
        // Proposers get an additional amount of tokens if proposal passes
        uint8 proposerAwardDivisor; 
        // Voters get an additional amount of tokens for voting on a proposal
        uint8 voterAwardDivisor; 
        // Cap voter and proposer token awards.
        // This is to help prevent too much inflation
        uint8 voteAwardCapDivisor;
    }

    function governanceStorage() internal pure returns(GovernanceStorage storage ds) {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
}
