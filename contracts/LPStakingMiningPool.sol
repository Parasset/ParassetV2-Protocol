// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "./lib/SafeMath.sol";
import './lib/SafeERC20.sol';

contract LPStakingMiningPool is ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	uint8 flag = 0;
	address asetTokenAddress;
	// Governance address
	address public governance;
	uint256 startTime;
	uint256 endTime;
	mapping(address=>uint256) userPoint;
	uint256 allPoint;
	uint256 allAset;

	mapping(address=>bool) stakingAllow;
	mapping(address=>mapping(address=>uint256)) balance;

	constructor(address aset) public {
		asetTokenAddress = aset;
		governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Log:InsurancePool:!gov");
        _;
    }

    function stake(address token, uint256 amount) public {
    	require(now > startTime && now < endTime, "Log:LPStakingMiningPool:!time");
    	uint256 thisPoint = amount.mul(endTime.sub(now));
    	userPoint[msg.sender] = userPoint[msg.sender].add(thisPoint);
    	allPoint = allPoint.add(thisPoint);
    	balance[msg.sender][token] = balance[msg.sender][token].add(amount);
    }

    function unStake(address token) public {
    	require(now > endTime, "Log:LPStakingMiningPool:!time");
    	ERC20(token).safeTransfer(msg.sender, balance[msg.sender][token]);
    	ERC20(asetTokenAddress).safeTransfer(msg.sender, allAset.mul(userPoint[msg.sender]).div(allPoint));
    	userPoint[msg.sender] = 0;
    	balance[msg.sender][token] = 0;
    }

    function addAset(uint256 amount) public onlyGovernance {
    	require(now < startTime, "Log:LPStakingMiningPool:!time");
    	ERC20(asetTokenAddress).safeTransferFrom(address(msg.sender), address(this), amount);
    	allAset = allAset.add(amount);
    }

}