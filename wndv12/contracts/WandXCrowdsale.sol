pragma solidity ^0.4.15;
  
import "./math/SafeMath.sol";
import './ownership/Ownable.sol';
import "./token/MintableToken.sol";
/**
 * @title WandXToken
 * @dev Very simple ERC20 Token that can be minted.
 * It is meant to be used in a crowdsale contract.
 */
contract WandXToken is MintableToken { 
  string public constant name = "WandX Token";
  string public constant symbol = "WAND";
  uint8 public constant decimals = 18; 
  uint public totalSupply = 10**27; // 1 billion tokens, 18 decimal places  
}

/**
 * @title WandXCrowdsale
 * @dev This is an example of a fully fledged crowdsale.
 * The way to add new features to a base crowdsale is by multiple inheritance.
 * In this example we are providing following extensions:
 * CappedCrowdsale - sets a max boundary for raised funds
 * RefundableCrowdsale - set a min goal to be reached and returns funds if it's not met
 *
 * After adding multiple features it's good practice to run integration tests
 * to ensure that subcontracts works together as intended.
 */
contract WandXCrowdsale is Ownable {
  using SafeMath for uint256; 

  uint256 public cap;

  // The token being sold
  address public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised; 

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  function startCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _goal, 
    uint256 _cap, address _wallet, address _token) onlyOwner public returns (bool)
  {
    require(_startTime >= now && _endTime >= _startTime); 
    require(_rate > 0);
    require(_wallet != 0x0);
    require(_cap > 0);  
    require(_goal <= _cap); 

    cap = _cap;  
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate; 
    wallet = _wallet;
    token = _token; 
    return true;
  } 
  
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(weiRaised.add(msg.value) <= cap);
    require(now >= startTime);
    require(now <= endTime);
    require(msg.value != 0);

    uint256 weiAmount = msg.value; 
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate); 
    // update state
    weiRaised = weiRaised.add(weiAmount); 
    WandXToken(token).mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    wallet.transfer(msg.value);
  } 
 
}