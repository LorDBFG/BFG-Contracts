// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts@4.7.3/token/ERC20/ERC20.sol";

contract AirdropFundContract {

    uint256 public maxBalance;
    uint256 public balance;
    address public owner;
    address public token;

    IERC20 itoken;

event TransferSent(address _from,address _destAddr,uint _amount);

    constructor(address _owner, IERC20 _itoken) {
            owner = _owner;
            itoken = _itoken;
       }

    function init() public onlyOwner{
        if(maxBalance==0){
            maxBalance = itoken.balanceOf(address(this));
        }
        balance = itoken.balanceOf(address(this));
    }

    function allocate(address to, uint256 amount) public onlyOwner{
        uint256 newBalance = itoken.balanceOf(address(this));

        if (maxBalance == 0){
            maxBalance = newBalance;
        }

        balance = newBalance;

        require(amount > 0 , "Need to request more than 0 BFG");
        require(balance > 0 , "No more BFG to collect");

        uint256 amountConverted = amount * 1000000000000000000;

        if(amountConverted > balance){
            amountConverted = balance;
        }

        itoken.transfer(to,amountConverted);
        balance-= amountConverted;

        emit TransferSent(address(this),to,amountConverted);
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