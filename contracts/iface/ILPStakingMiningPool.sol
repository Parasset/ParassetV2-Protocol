// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ILPStakingMiningPool {
	function getBalance(address user) external view returns(uint256);
}