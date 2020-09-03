// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0;

import '../interfaces/IQuickSwapFactory.sol';
import '../QuickSwapPair.sol';

contract QuickSwapFactory is IQuickSwapFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;  

    constructor() {
        feeToSetter = address(this);
        feeTo = address(this);
    }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'QuickSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'QuickSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'QuickSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(QuickSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IQuickSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'QuickSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'QuickSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
