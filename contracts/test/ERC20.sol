// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.1;

import '../QuickSwapERC20.sol';

contract ERC20 is QuickSwapERC20 {
    constructor(uint _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }
}
