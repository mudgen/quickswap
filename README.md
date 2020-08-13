# Matic Swap

Deploys token trading contracts on Matic Network.

Execute this to deploy:

`truffle migrate --network matic`

Matic Mumbai Network contract addresses:

* UniswapV2Factory: `0x4A271b59763D4D8A18fF55f1FAA286dE97317B15`
* UniswapV2Router02: `0xDf36944e720cf5Af30a3C5D80d36db5FB71dDE40`

# Changes from Uniswap V2

The code in this project was originally taken from these three repositories:
* https://github.com/Uniswap/uniswap-lib
* https://github.com/Uniswap/uniswap-v2-core
* https://github.com/Uniswap/uniswap-v2-periphery

Code from the above repositories were combined into this one and they were upgraded to use Solidity 0.7.0.
These changes occurred on 12 August 2020.

The code from these repositories are used as a base for token trading on Matic Network.

See CHANGES.md for further changes.

Nick Mudge <nick@perfectabstractions.com>

https://twitter.com/mudgen


