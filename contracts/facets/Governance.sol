// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1;
pragma experimental ABIEncoderV2;


import { IERC20 } from '../interfaces/IERC20.sol';
import * as util from '../libraries/Util.sol';
import * as gsf from '../storage/GovernanceStorage.sol';


contract Governance {
    
    event Propose(address _proposer, address _proposalContract, uint _endTime);
    event Vote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);
    event UnVote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);     
    event ProposalExecutionSuccessful(uint _proposalId, bool _passed);
    event ProposalExecutionFailed(uint _proposalId, bytes _error);     

    function proposalCount() external view returns (uint) {
        return gsf.governanceStorage().proposalCount;
    }

    function propose(address _proposalContract, uint _endTime) external returns (uint proposalId) {
        uint contractSize;
        assembly { contractSize := extcodesize(_proposalContract) }
        require(contractSize > 0, 'Governance: Proposed contract is empty');
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();        
        require(_endTime > block.timestamp + (gs.minimumVotingTime * 3600), 'Governance: Voting time must be longer');
        require(_endTime < block.timestamp + (gs.maximumVotingTime * 3600), 'Governance: Voting time must be shorter');
       
        uint proposerBalance = gs.balances[msg.sender];
        uint totalSupply = gs.totalSupply;        
        require(proposerBalance >= (totalSupply / gs.proposalThresholdDivisor), 'Governance: Balance less than proposer threshold');
        proposalId = gs.proposalCount++;
        gsf.Proposal storage proposalStorage = gs.proposals[proposalId];
        proposalStorage.proposer = msg.sender;
        proposalStorage.proposalContract = _proposalContract;
        proposalStorage.endTime = uint64(_endTime);
        emit Propose(msg.sender, _proposalContract, _endTime);
        // adding vote
        proposalStorage.forVotes = uint96(proposerBalance);
        proposalStorage.voted[msg.sender] = gsf.Voted(uint96(proposerBalance), true);
        gs.votedProposalIds[msg.sender].push(uint24(proposalId));
        emit Vote(proposalId, msg.sender, proposerBalance, true);
    }

    function executeProposal(uint _proposalId) external {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        gsf.Proposal storage proposalStorage = gs.proposals[_proposalId];
        address proposer = proposalStorage.proposer;
        require(proposer != address(0), 'Governance: Proposal does not exist');
        require(block.timestamp > proposalStorage.endTime, 'Governance: Voting hasn\'t ended');        
        require(proposalStorage.executed != true, 'Governance: Proposal has already been executed');
        proposalStorage.executed = true;
        uint totalSupply = gs.totalSupply;
        uint forVotes = proposalStorage.forVotes;
        uint againstVotes = proposalStorage.againstVotes;
        bool proposalPassed = forVotes > againstVotes && forVotes > gs.totalSupply / gs.quorumDivisor;
        uint votes = proposalStorage.voted[proposer].votes;        
        if(proposalPassed) {
            address proposalContract = proposalStorage.proposalContract;
            uint contractSize;            
            assembly { contractSize := extcodesize(proposalContract) }
            if(contractSize > 0) {                        
                (bool success, bytes memory error) = proposalContract.delegatecall(abi.encodeWithSignature('execute', _proposalId));                
                if(success) {
                    if(totalSupply < gs.totalSupplyCap) {
                        uint fractionOfTotalSupply = totalSupply / gs.voteAwardCapDivisor;
                        if(votes > fractionOfTotalSupply) {
                            votes = fractionOfTotalSupply;
                        }
                        // 5 percent reward
                        uint proposerAwardDivisor = gs.proposerAwardDivisor;
                        gs.totalSupply += uint96(votes / proposerAwardDivisor);
                        gs.balances[proposer] += votes / proposerAwardDivisor;
                    }
                    emit ProposalExecutionSuccessful(_proposalId, true);
                }
                else {
                    proposalStorage.stuck = true;
                    proposalStorage.executed = false;
                    emit ProposalExecutionFailed(_proposalId, error);                                
                }
            }
            else {
                proposalStorage.stuck = true;
                proposalStorage.executed = false;
                emit ProposalExecutionFailed(_proposalId, bytes('Proposal contract size is 0'));
            }
        }
        else {
            gs.balances[proposer] -= votes;
            emit ProposalExecutionSuccessful(_proposalId, false);
        }                
    }

    enum ProposalStatus { 
        NoProposal,
        PassedAndReadyForExecution, 
        RejectedAndReadyForExecution,
        PassedAndExecutionStuck,
        VotePending,
        Passed,  
        Rejected        
    }

    function proposalStatus(uint _proposalId) public view returns (ProposalStatus status) {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        gsf.Proposal storage proposalStorage = gs.proposals[_proposalId];
        uint endTime = proposalStorage.endTime;
        if(endTime == 0) {
            status = ProposalStatus.NoProposal;
        }
        else if(block.number < endTime) {
            status = ProposalStatus.VotePending;
        }
        else if(proposalStorage.stuck) {
            status = ProposalStatus.PassedAndExecutionStuck;
        }
        else {
            uint forVotes = proposalStorage.forVotes;
            bool passed = forVotes > proposalStorage.againstVotes && forVotes > gs.totalSupply / gs.quorumDivisor;
            if(proposalStorage.executed) {
                if(passed) {
                    status = ProposalStatus.Passed;
                }
                else {
                    status = ProposalStatus.Rejected;
                }
            }
            else {
                if(passed) {
                    status = ProposalStatus.PassedAndReadyForExecution;
                }
                else {
                    status = ProposalStatus.RejectedAndReadyForExecution;
                }
            }
        }
    }
    
    struct RetrievedProposal {
        address proposalContract;
        address proposer;
        uint64 endTime;                
        uint96 againstVotes;
        uint96 forVotes;
        ProposalStatus status;
    }

    function proposal(uint _proposalId) external view returns (RetrievedProposal memory retrievedProposal) {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        gsf.Proposal storage proposalStorage = gs.proposals[_proposalId];
        retrievedProposal = RetrievedProposal({
            proposalContract: proposalStorage.proposalContract,
            proposer: proposalStorage.proposer,
            endTime: proposalStorage.endTime,                        
            againstVotes: proposalStorage.againstVotes,
            forVotes: proposalStorage.forVotes,
            status: proposalStatus(_proposalId)
        });        
    }

    function vote(uint _proposalId, bool _support) external {
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        require(_proposalId < gs.proposalCount, 'Governance: _proposalId does not exist');
        gsf.Proposal storage proposalStorage = gs.proposals[_proposalId];
        require(block.timestamp < proposalStorage.endTime, 'Governance: Voting ended');
        require(proposalStorage.voted[msg.sender].votes == 0, 'Governance: Already voted');        
        uint balance = gs.balances[msg.sender];
        if(_support) {
            proposalStorage.forVotes += uint96(balance);
        }
        else {
            proposalStorage.againstVotes += uint96(balance);
        }
        proposalStorage.voted[msg.sender] = gsf.Voted(uint96(balance), _support);
        gs.votedProposalIds[msg.sender].push(uint24(_proposalId));
        emit Vote(_proposalId, msg.sender, balance, _support);        
        uint totalSupply = gs.totalSupply;
        if(totalSupply < gs.totalSupplyCap) {
            // Reward voter with increase in token            
            uint fractionOfTotalSupply = gs.totalSupply / gs.voteAwardCapDivisor;
            if(balance > fractionOfTotalSupply) {
                balance = fractionOfTotalSupply;
            }
            uint voterAwardDivisor = gs.voterAwardDivisor;
            gs.totalSupply += uint96(balance / voterAwardDivisor);
            gs.balances[msg.sender] += balance / voterAwardDivisor;
        }
    }

    function unvote(uint _proposalId) external {        
        gsf.GovernanceStorage storage gs = gsf.governanceStorage();
        require(_proposalId < gs.proposalCount, 'Governance: _proposalId does not exist');
        gsf.Proposal storage proposalStorage = gs.proposals[_proposalId];
        require(block.timestamp < proposalStorage.endTime, 'Governance: Voting ended'); 
        require(proposalStorage.proposer != msg.sender, 'Governance: Can\'t unvote your own proposal');       
        uint votes = proposalStorage.voted[msg.sender].votes;
        bool support = proposalStorage.voted[msg.sender].support;
        require(votes > 0, 'Governance: Did not vote');                
        if(support) {
            proposalStorage.forVotes -= uint96(votes);
        }
        else {
            proposalStorage.againstVotes -= uint96(votes);
        }
        delete proposalStorage.voted[msg.sender];
        uint24[] storage proposalIds = gs.votedProposalIds[msg.sender];
        uint length = proposalIds.length;
        uint index;
        for(; index < length; index++) {
            if(uint(proposalIds[index]) == _proposalId) {
                break;
            }
        }
        uint lastIndex = length-1;
        if(lastIndex != index) {
            proposalIds[index] = proposalIds[lastIndex];    
        }
        proposalIds.pop();
        emit UnVote(_proposalId, msg.sender, votes, support);
        // Remove voter reward
        uint voterAwardDivisor = gs.voterAwardDivisor;
        gs.totalSupply -= uint96(votes / voterAwardDivisor);
        gs.balances[msg.sender] -= votes / voterAwardDivisor;
    }

}