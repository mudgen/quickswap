# QuickSwap

Deploys token trading contracts on Matic Network.

Execute this to deploy:

`truffle migrate --network matic`

Matic Mumbai Network contract addresses:

* Diamond: `0x4fe23a33922BcC5e560fdd74A84cDDe4D2BdaaAC`
* QuickSwapRouter02: `0xFCB5348111665Cf95a777f0c4FCA768E05601760`

# Changes from Uniswap V2

The code in this project was originally taken from these three repositories:
* https://github.com/Uniswap/uniswap-lib
* https://github.com/Uniswap/uniswap-v2-core
* https://github.com/Uniswap/uniswap-v2-periphery

Code from the above repositories were combined and integrated into this one and they were upgraded to use Solidity 0.7.0.
These changes occurred on 12 August 2020.

The code from these repositories are used as a base for token trading on Matic Network.

The uniswap code was also integrated with a [diamond](https://eips.ethereum.org/EIPS/eip-2535) and governance and governance token contracts.

See CHANGES.md for further changes.

Nick Mudge <nick@perfectabstractions.com>

https://twitter.com/mudgen


