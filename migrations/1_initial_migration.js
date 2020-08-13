const Migrations = artifacts.require("Migrations");
//  0x47195A03fC3Fc2881D084e8Dc03bD19BE8474E46
module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
