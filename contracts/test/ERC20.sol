// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.1;

import '../QuickSwapLiquidityToken.sol';

contract ERC20 is QuickSwapLiquidityToken {
    constructor(uint _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }
}
