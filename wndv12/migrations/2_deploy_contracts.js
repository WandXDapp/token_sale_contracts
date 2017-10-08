var SafeMath = artifacts.require("./math/SafeMath.sol");
var Ownable = artifacts.require("./ownership/Ownable.sol");
var BasicToken = artifacts.require("./token/BasicToken.sol");
var StandardToken = artifacts.require("./token/StandardToken.sol");
var MintableToken = artifacts.require("./token/MintableToken.sol");  
var WandXCrowdsale = artifacts.require("./WandXCrowdsale.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.deploy(Ownable);

  deployer.link(SafeMath, BasicToken); 
  deployer.link(SafeMath, WandXCrowdsale);

  deployer.deploy(BasicToken);
  deployer.deploy(StandardToken);
  deployer.deploy(MintableToken);  
  deployer.deploy(WandXCrowdsale, {gas: 4500000});
};
