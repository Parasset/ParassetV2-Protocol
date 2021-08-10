// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import './lib/TransferHelper.sol';
import "./iface/ILPStakingMiningPool.sol";
import "./iface/IERC20.sol";
import "./ParassetBase.sol";

contract LPStakingMiningPool is ParassetBase, ILPStakingMiningPool {

	// ASET
    address public _rewardsToken;
    
    // token => channel info
    mapping(address => Channel) _tokenChannel;
    struct Channel {
        // recently operated block
        // 上限4294967295
        uint32 lastUpdateBlock;
        // end block
        // 上限4294967295
        uint32 endBlock;
        // revenue efficiency
        uint192 rewardRate;
        // profit per share
        uint256 rewardPerTokenStored;
        // total locked position
        uint256 totalSupply;
        // user address => Account info
        mapping(address => Account) accounts;
    }

    struct Account {
        // locked position
        uint256 balance;
        // latest profit per share
        uint256 userRewardPerTokenPaid;
    }

    //---------view---------

    /// @dev Get the endBlock
    /// @param endBlock block number at the end of this mining cycle
    /// @return actual ending block number
    function getBlock(uint256 endBlock) public view override returns(uint256) {
        uint256 nowBlock = block.number;
        if (nowBlock > endBlock) {
            return endBlock;
        }
        return nowBlock;
    }
    
    /// @dev Get the amount of locked funds
    /// @param stakingToken staking token address
    /// @param account user address
    /// @return the amount of locked staked token
    function getBalance(
        address stakingToken, 
        address account
    ) external view override returns(uint256) {
        return _tokenChannel[stakingToken].accounts[account].balance;
    }

    /// @dev Get the lock channel information
    /// @param stakingToken staking token address
    /// @return lastUpdateBlock the height of the recently operated block
    /// @return endBlock mining end block
    /// @return rewardRate mining efficiency per block
    /// @return rewardPerTokenStored receivable mine per share
    /// @return totalSupply total locked position
    function getChannelInfo(
        address stakingToken
    ) external view override returns (
        uint256 lastUpdateBlock, 
        uint256 endBlock, 
        uint256 rewardRate, 
        uint256 rewardPerTokenStored, 
        uint256 totalSupply
    ) {
        Channel storage channelInfo = _tokenChannel[stakingToken];
        return (channelInfo.lastUpdateBlock, 
                channelInfo.endBlock, 
                channelInfo.rewardRate, 
                channelInfo.rewardPerTokenStored, 
                channelInfo.totalSupply);
    }

    /// @dev Get the estimated number of receivables
    /// @param stakingToken staking token address
    /// @param account user address
    /// @return the estimated number of receivables
    function getAccountReward(
        address stakingToken, 
        address account
    ) external view override returns(uint256) {
        Channel storage channelInfo = _tokenChannel[stakingToken];
        (,,uint256 userReward) = _calcReward(channelInfo, account);
        return userReward;
    }

    /// @dev Get the account data
    /// @param stakingToken staking token address
    /// @param account user address
    /// @return balance the amount of locked staked token
    /// @return userRewardPerTokenPaid receivable mine per share
    function getAccountInfo(
        address stakingToken, 
        address account
    ) external view returns(
        uint256 balance, 
        uint256 userRewardPerTokenPaid
    ) {
        Account memory accountInfo = _tokenChannel[stakingToken].accounts[account];
        return (accountInfo.balance, accountInfo.userRewardPerTokenPaid);
    }

    function _calcReward(
        Channel storage channelInfo,
        address account
    ) private view returns(
        uint32 _nowBlock, 
        uint256 _rewardPerTokenStored, 
        uint256 _userReward
    ) {
        uint256 nowBlock = getBlock(channelInfo.endBlock);
        uint256 totalSupply = channelInfo.totalSupply;
        uint256 rewardPerTokenStored = channelInfo.rewardPerTokenStored;
        uint256 lastUpdateBlock = channelInfo.lastUpdateBlock;
        uint256 accrued = (lastUpdateBlock == 0 ? 0 : (nowBlock - lastUpdateBlock) * channelInfo.rewardRate);

        _nowBlock = uint32(nowBlock);
        _rewardPerTokenStored = (totalSupply == 0 ? 
                                rewardPerTokenStored : 
                                (rewardPerTokenStored + accrued * 1e18 / totalSupply));
        _userReward = channelInfo.accounts[account].balance
                      * (_rewardPerTokenStored 
                      - channelInfo.accounts[account].userRewardPerTokenPaid)
                      / 1e18;
    }

    //---------governance----------

    /// @dev Set up mining token
    function setRewardsToken(address add) external onlyGovernance {
        _rewardsToken = add;
    }

    /// @dev Increase mining token (open mining)
    /// @param tokenAmount increase the number of token
    /// @param from mining token transfer address
    /// @param rewardRate mining efficiency per block
    /// @param stakingToken staking token address
    function addToken(
        uint256 tokenAmount, 
        address from, 
        uint96 rewardRate, 
        address stakingToken
    ) external onlyGovernance {
    	TransferHelper.safeTransferFrom(_rewardsToken, from, address(this), tokenAmount);
        Channel storage channelInfo = _tokenChannel[stakingToken];
    	channelInfo.lastUpdateBlock = uint32(block.number);
        channelInfo.rewardRate = rewardRate;
    	channelInfo.endBlock = uint32(tokenAmount / rewardRate + block.number);
    }

    /// @dev Set the lock channel information
    /// @param lastUpdateBlock the height of the recently operated block
    /// @param endBlock mining end block
    /// @param rewardRate mining efficiency per block
    /// @param stakingToken staking token address
    function setChannelInfo(
        uint32 lastUpdateBlock, 
        uint32 endBlock, 
        uint96 rewardRate,
        address stakingToken
    ) external onlyGovernance {
        Channel storage channelInfo = _tokenChannel[stakingToken];
        // settlement
        (, uint256 rewardPerTokenStored,) = _calcReward(channelInfo, address(this));
        channelInfo.rewardPerTokenStored = rewardPerTokenStored;
        // update
        channelInfo.lastUpdateBlock = lastUpdateBlock;
        channelInfo.endBlock = endBlock;
        channelInfo.rewardRate = rewardRate;
    }

    //---------transaction---------

    /// @dev Stake
    /// @param amount amount of stake token
    /// @param stakingToken staking token address
    function stake(uint256 amount, address stakingToken) external override nonReentrant {
        require(amount > 0, "Log:LPStakingMiningPool:!0");

        Channel storage channelInfo = _tokenChannel[stakingToken];
        _getReward(channelInfo, msg.sender);

        TransferHelper.safeTransferFrom(stakingToken, msg.sender, address(this), amount);

    	channelInfo.totalSupply = channelInfo.totalSupply + amount;
        channelInfo.accounts[msg.sender].balance = channelInfo.accounts[msg.sender].balance + amount;
    }

    /// @dev Withdraw
    /// @param amount amount of stake token
    /// @param stakingToken staking token address
    function withdraw(uint256 amount, address stakingToken) external override nonReentrant {
        require(amount > 0, "Log:LPStakingMiningPool:!0");

        Channel storage channelInfo = _tokenChannel[stakingToken];
        _getReward(channelInfo, msg.sender);

        channelInfo.totalSupply = channelInfo.totalSupply - amount;
        channelInfo.accounts[msg.sender].balance = channelInfo.accounts[msg.sender].balance - amount;

    	TransferHelper.safeTransfer(stakingToken, msg.sender, amount);
    }

    /// @dev Receive income
    /// @param stakingToken staking token address
    function getReward(address stakingToken) external override nonReentrant {
        Channel storage channelInfo = _tokenChannel[stakingToken];
        _getReward(channelInfo, msg.sender);
    }

    function _getReward(Channel storage channelInfo, address to) private {
        (uint32 lastUpdateBlock, uint256 rewardPerTokenStored, uint256 userReward) = _calcReward(channelInfo, to);

        channelInfo.rewardPerTokenStored = rewardPerTokenStored;
        channelInfo.lastUpdateBlock = lastUpdateBlock;

        if (to != address(0)) {
            if (userReward > 0) {
                // transfer ASET
                _safeAsetTransfer(to, userReward);
            }
            channelInfo.accounts[to].userRewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    function _safeAsetTransfer(address to, uint256 amount) private returns (uint256) {
        uint256 asetBal = IERC20(_rewardsToken).balanceOf(address(this));
        if (amount > asetBal) {
            amount = asetBal;
        }
        // allow zero amount
        TransferHelper.safeTransfer(_rewardsToken, to, amount);
        return amount;
    }
}