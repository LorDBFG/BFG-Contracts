// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TeamContract {
    uint256 public maxBalance;
    uint256 public balance;
    uint256 public lastUnlockTime;
    address public owner;
    IERC20 itoken;
    address public bfgTokenAddress;
    mapping(address => uint8) public shares;
    mapping(address => uint256) public balances;
    address[] public members;
    uint public vestingCycles;
    uint8 public totalShares = 0;
    uint8 public memberLength = 7;

event TransferSent(address _from,address _destAddr,uint _amount);


       constructor(address _owner,uint8 share,IERC20 _itoken) {
            itoken = _itoken;
            bfgTokenAddress = address(itoken);
            owner = _owner;
            members.push(_owner);
            totalShares = share;
            shares[_owner] = share;
            lastUnlockTime = 1665243000;
            vestingCycles = 0;
       }

    function init() public onlyOwner{
        if(maxBalance==0){
            maxBalance = itoken.balanceOf(address(this));
        }
        balance = itoken.balanceOf(address(this));
    }

    function AddMember(address member,uint8 share) public onlyOwner{
        
        require(vestingCycles == 0, "Changes not allowed after vesting starts");
        require(share > 0 , "Shares must be positive numbers");
        require(shares[member] == 0, "Member already added");
        require(members.length <= memberLength-1,"All team members added");
        require(share+totalShares <= 100, "Share percentage exceeds 100%");
        
        shares[member] = share;
        totalShares += share;
        members.push(member);
    }

    //function RemoveMember(uint index, address _address) public onlyOwner{
    //    require(vestingCycles == 0, "Changes not allowed after vesting starts");
    //    require(index <= members.length,"Not a valid user");
    //    require(members[index] == _address, "Address not complatible with index");
    //    totalShares -= shares[_address];
    //    shares[_address] = 0;
    //    members[index] = members[members.length - 1];
    //    members.pop();   
    //}

    //withdraw tokens 
    function WithdrawToMember() public onlyMember{
        require(balances[msg.sender] > 0,"Not enough unlocked tokens");
        
        itoken.transfer(msg.sender,balances[msg.sender]);
        balances[msg.sender] = 0;

        emit TransferSent(address(this),msg.sender,balances[msg.sender]);
    }

    //unlock vested tokens if ready
    function Unlock() public onlyMember{
        
        require(totalShares == 100, "Need 100% shares added to start Unlock");
        
        if (maxBalance <= 0){
            uint256 newBalance = itoken.balanceOf(address(this));
            maxBalance = newBalance;
        }

        //12 months cliff
        if (vestingCycles == 0){
            require(block.timestamp > lastUnlockTime + 360 days,"Too early for unlocking tokens");
            calc(0, 360 days);
            return;
        }

        if (balance <= 0){
            uint256 newBalance = itoken.balanceOf(address(this));
            balance = newBalance;
        }
        //unlock 3.5% each month
        // unlock 0,104% linear daily 32 months (100%) (960 days)
        if (vestingCycles > 0){
            if(lastUnlockTime == 1665243000){
                lastUnlockTime= 1665243000 + 360 days;
            }
            require(block.timestamp > lastUnlockTime + 1 days, "Too early for unlocking tokens");
            uint8 daysPast = uint8((block.timestamp - lastUnlockTime) / 60 / 60 / 24);
            require(daysPast > 0, "Too early for unlock");
            
            calc(104 * daysPast, daysPast * 1 days);
        }
    }
    
    function calc(uint16 x,uint256 y) internal{
            require(balance > 0, "No more tokens for unlock");
            if(x > 0){
                uint256 newTokens = maxBalance * x / 100000;
                if(newTokens > balance){
                    newTokens = balance;
                }
                for (uint8 i = 0; i < members.length; i++) {  //for loop example dont need /100
                    uint256 memberTokens = shares[members[i]] * newTokens / 100; 
                    balances[members[i]] += memberTokens;
                }
                balance -= newTokens;
                lastUnlockTime += y;
                vestingCycles += x/104;
            }
            if(x==0){
                lastUnlockTime += y;
                vestingCycles ++;
            }
            
    }

    modifier onlyMember() {
         require(shares[msg.sender] > 0,"Only members");
        _;
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