// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts@4.7.3/token/ERC20/ERC20.sol";

contract EcosystemFundContract {

    uint256 public maxBalance;
    uint256 public balance;
    address public owner;
    address public token;
    uint256 public lastUnlockTime;
    IERC20 itoken;
    
    uint16 public vestingCycles;

    event TransferSent(address _from,address _destAddr,uint _amount);

        constructor(address _owner, IERC20 _itoken) {
            owner = _owner;
            token = address(_itoken);
            itoken = _itoken;
            lastUnlockTime = 1665243000;
            vestingCycles = 0;
       }

    function init() public onlyOwner(){
        if(maxBalance == 0){
            maxBalance = itoken.balanceOf(address(this));
        }
        balance = itoken.balanceOf(address(this));
    }

    function Withdraw(address _address, uint256 amount) public onlyOwner{
        uint256 newBalance = itoken.balanceOf(address(this));
        
        if (maxBalance == 0){
            maxBalance = newBalance;
        }

        balance = newBalance;

        require(amount > 0 , "Need to request more than 0 BFG");
        require(balance > 0 , "No more BFG to collect");
      
        //3 months cliff
		if(vestingCycles == 0){
			require(block.timestamp > lastUnlockTime + 90 days , "Too early for unlocking tokens");
			lastUnlockTime = lastUnlockTime + 90 days;
            vestingCycles ++;
            return;
		}
        //Unlocked
		if(vestingCycles > 0){
            uint256 amountConverted = amount * 1000000000000000000;
			
            if(amountConverted > balance){
                amountConverted = balance;
            }

			itoken.transfer(_address,amountConverted);
            balance-=amountConverted;
            lastUnlockTime = block.timestamp;
            vestingCycles++;

            emit TransferSent(address(this),_address,amountConverted);
		}
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "can't have owner with zero address");
        owner = newOwner;
    }

}