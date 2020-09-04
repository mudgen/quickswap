const Diamond = artifacts.require("Diamond");
const UniswapV2Router02 = artifacts.require("UniswapV2Router02");

module.exports = function(deployer, network, accounts) {  
  const weth = "0x670568761764f53E6C10cd63b71024c31551c9EC";  
  // UniswapV2Factory: 0x4A271b59763D4D8A18fF55f1FAA286dE97317B15
  deployer.deploy(Diamond).then(function() {
    // UniswapV2Router02: 0xDf36944e720cf5Af30a3C5D80d36db5FB71dDE40
    return deployer.deploy(UniswapV2Router02, Diamond.address, weth)
  });
};

/*
module.exports = function(deployer, network, accounts) {    
  deployer.deploy(UniswapV2Factory, accounts[0]);
};
*/