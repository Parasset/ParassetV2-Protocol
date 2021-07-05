// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ILPStakingMiningPool {
	function getBlock(uint256 endBlock) external view returns(uint256);
	function getBalance(address stakingToken, address account) external view returns(uint256);
	function getChannelInfo(address stakingToken) external view returns(uint256 lastUpdateBlock, uint256 endBlock, uint256 rewardRate, uint256 rewardPerTokenStored, uint256 totalSupply);
	function getAccountReward(address stakingToken, address account) external view returns(uint256);
	function stake(uint256 amount, address stakingToken) external;
	function withdraw(uint256 amount, address stakingToken) external;
	function getReward(address stakingToken) external;
}