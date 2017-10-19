pragma solidity ^0.4.15;
 
import "./MintableToken.sol";

/**
 * @title Wand token
 * @dev Customized mintable ERC20 Token  
 * @dev Token to support multiple Capped CrowdSales. i.e. every crowdsale with capped token limit and also
        we will be able to increase total token supply based on requirements
 */
contract WandToken is Ownable, MintableToken { 
  //Event for Presale transfers
  event TokenPreSaleTransfer(address indexed purchaser, address indexed beneficiary, uint256 amount);
  
  // Token details
  string public constant name = "Wand Token";
  string public constant symbol = "WAND";

  // 18 decimal places, the same as ETH.
  uint8 public constant decimals = 18;

  /**
    @dev Constructor. Sets the initial supplies and transfer advisor/founders/presale tokens to the given account
    @param _owner The address the account nto which presale tokens + Advisors/founders tokens transferred
   */
  function WandToken(address _owner) {
      //Total of 75M tokens
      totalSupply = 75 * 10**24;  

      // 17M tokens for Funders+advisors, 3.4M for PreSales
      tokensMinted = tokensMinted.add(20400000 * (1 ether));
      balances[_owner] = 20400000 * 1 ether;
  }   

  /**
    @dev function to handle presale trasnfers manually. Only owner can execute the contract
    @param _accounts buyers accounts that will receive the presale tokens
    @param _tokens   Amount of the tokens to be transferred to each account in _accounts list 
    @return A boolean that indicates if the operation is successful.
   */
  function batchTransfers(address[] _accounts, uint256[] _tokens) onlyOwner public returns (bool) {
    require(_accounts.length > 0);
    require(_accounts.length == _tokens.length); 
    for (uint i = 0; i < _accounts.length; i++) {
      require(_accounts[i] != 0x0);
      require(_tokens[i] > 0); 
      transfer(_accounts[i], _tokens[i] * 1 ether);
      TokenPreSaleTransfer(msg.sender, _accounts[i], _tokens[i]); 
    }
    return true;   
  }
  
  /**
    @dev function to raise the total supply. Method can be executed only by its owner
    @param _supply delta number of tokens to be added to total supply 
    @return A boolean that indicates if the operation is successful.
   */
  function raiseInitialSupply(uint256 _supply) onlyOwner public returns (bool) {
      totalSupply = totalSupply.add(_supply * 1 ether);
      return true;
  }
}