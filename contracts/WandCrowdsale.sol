pragma solidity ^0.4.15;

import "./math/SafeMath.sol";
import "./token/WandToken.sol";
import "./ownership/Ownable.sol";

/**
 * @title Wandx CrowSale/ICO contract 
 * @dev It allows multiple Capped CrowdSales. i.e. every crowdsale with capped token limit. 
 * @dev exposes 2 more proxy methods from token contract which can be executed only by this contract owner
 */
contract WandCrowdsale is Ownable
{ 
    using SafeMath for uint256; 
     
    // The token being sold
    WandToken public token;  
    // the account tp which all incoming ether will be transferred
    address public wallet;
    // Flag to track the crowdsale status (Active/InActive)
    bool public crowdSaleOn = false;  

    // Current crowsale sate variables
    uint256 public cap = 0;  // Max allowed tokens to avaialble
    uint256 public startTime; // Crowdsale start time
    uint256 public endTime;  // Crowdsale end time
    uint256 public weiRaised = 0;  // Total amount ether/wei collected
    uint256 public tokensMinted = 0; // Total number of tokens minted/sold so far in this crowdsale
    uint256[] public discountedRates ; // Discount per slot
    uint256[] public crowsaleSlots ; // List of slots
    
    // Event to be registered when a successful token purchase happens
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    /** Modifiers to verify the status of the crowdsale*/
    modifier activeCrowdSale() {
        require(crowdSaleOn);
        _;
    } 
    modifier inactiveCrowdSale() {
        require(!crowdSaleOn);
        _;
    } 
    
    /**
        @dev constructor. Intializes the wallets and tokens to be traded using this contract
     */
    function WandCrowdsale() { 
        wallet = msg.sender;  
        token = new WandToken(msg.sender);
    }
    
    /**
      @dev proxy method for Wand Tokens batch transfers method, so that contract owner can call token methods
      @param _accounts buyers accounts that will receive the presale tokens
      @param _tokens   Amount of the tokens to be transferred to each account in _accounts list 
      @return A boolean that indicates if the operation is successful. 
     */
    function batchTransfers(address[] _accounts, uint256[] _tokens) onlyOwner public returns (bool) {
        require(_accounts.length > 0);
        require(_accounts.length == _tokens.length); 
        token.batchTransfers(_accounts,_tokens);
        return true;
    }
    
    /**
      @dev proxy method for Wand Tokens raiseInitialSupply method, so that contract owner can call token methods
      @param _supply delta number of tokens to be added to total supply 
      @return A boolean that indicates if the operation is successful.
     */
    function raiseInitialSupply(uint256 _supply) onlyOwner public returns (bool) {
        require(_supply > 0);
        token.raiseInitialSupply(_supply);
        return true;
    }
    
    /**
      @dev function to start the crowdsale with predefined timeslots and discounts. it will be called once for every crowdsale session and 
           it can be called only its owner
      @param _startTime at which crowdsale begins
      @param _endTime at which crowdsale stops
      @param _cap is number of tokens available during the crowdsale
      @param _crowsaleSlots array of time slots
      @param _discountedRates array of discounts 
      @return A boolean that indicates if the operation is successful
     */
    function startCrowdsale(uint256 _startTime, uint256 _endTime,  uint256 _cap, uint256[] _crowsaleSlots, uint256[] _discountedRates) inactiveCrowdSale onlyOwner public returns (bool) {  
        require(_cap > 0);   
        require(_crowsaleSlots.length > 0); 
        require(_crowsaleSlots.length == _discountedRates.length);
        require(_startTime >= uint256(now));  
        require( _endTime > _startTime); 
        
        //sets the contract state for this crowdsale
        cap = _cap * 1 ether;  //Normalized the cap to operate at wei units level
        startTime = _startTime;
        endTime = _endTime;    
        crowdSaleOn = true;
        weiRaised = 0;
        tokensMinted = 0;
        discountedRates = _discountedRates;
        crowsaleSlots = _crowsaleSlots;
        return true;
    }  

    /**
      @dev function to stop crowdsale session.it will be called once for every crowdsale session and it can be called only its owner
      @return A boolean that indicates if the operation is successful
     */
    function endCrowdsale() activeCrowdSale onlyOwner public returns (bool) {
        endTime = now;  
        if(tokensMinted < cap){
            uint256 leftoverTokens = cap.sub(tokensMinted);
            require(tokensMinted.add(leftoverTokens) <= cap);
            tokensMinted = tokensMinted.add(leftoverTokens);
            token.mint(owner, leftoverTokens.div(1 ether)); 
        }
        crowdSaleOn = false;
        return true;
    }   
    
    /**
      @dev function to calculate and return the discounted token rate based on the current timeslot
      @return _discountedRate for the current timeslot
     */
    function findDiscount() constant private returns (uint256 _discountedRate) {
        uint256 elapsedTime = now.sub(startTime);
        for(uint i=0; i<crowsaleSlots.length; i++){
            if(elapsedTime >= crowsaleSlots[i]) {
                elapsedTime = elapsedTime.sub(crowsaleSlots[i]);
            }
            else {
                _discountedRate = discountedRates[i];
                break;
            }
        } 
    }
    
    /**
      @dev  fallback function can be used to buy tokens
      */
    function () payable {
        buyTokens(msg.sender);
    }
  
    /**
      @dev  low level token purchase function
      */
    function buyTokens(address beneficiary) activeCrowdSale public payable {
        require(beneficiary != 0x0); 
        require(now >= startTime);
        require(now <= endTime);
        require(msg.value != 0);   
        
        // amount ether sent to the contract.. normalized to wei
        uint256 weiAmount = msg.value; 
        weiRaised = weiRaised.add(weiAmount); 
        
        // apply the discount based on timeslot and get the token rate (X tokens per 1 ether)
        var currentRate = findDiscount();
        // Find out Token value in wei ( Y wei per 1 Token)
        uint256 rate = uint256(1 * 1 ether).div(currentRate); 
        require(rate > 0);
        // Find out the number of tokens for given wei and normalize to ether so that tokens can be minted
        // by token contract
        uint256 numTokens = weiAmount.div(rate); 
        require(numTokens > 0); 
        require(tokensMinted.add(numTokens.mul(1 ether)) <= cap);
        tokensMinted = tokensMinted.add(numTokens.mul(1 ether));
        
        // Mint the tokens and trasfer to the buyer
        token.mint(beneficiary, numTokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, numTokens); 
        // Transfer the ether to Wallet and close the purchase
        wallet.transfer(weiAmount);
    } 
}