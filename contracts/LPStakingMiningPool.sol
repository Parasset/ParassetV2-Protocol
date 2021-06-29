// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import './lib/TransferHelper.sol';
import "./lib/ReentrancyGuard.sol";
import "./iface/ILPStakingMiningPool.sol";
import "./iface/IERC20.sol";

contract LPStakingMiningPool is ReentrancyGuard, ILPStakingMiningPool {

	// ASET
    address public _rewardsToken;
    // lp token address
    address public _stakingToken;
    // governance
    address public _governance;
    // recently operated block
    uint256 public _lastUpdateBlock;
    // profit per share
    uint256 public _rewardPerTokenStored;
    // revenue efficiency
    uint256 public _rewardRate;
    // total locked position
    uint256 public _totalSupply;
    // end block
    uint256 public _endBlock;
    // user address => latest profit per share
    mapping(address => uint256) public userRewardPerTokenPaid;
    // user address => income
    mapping(address => uint256) public rewards;
    // user address => locked position
    mapping(address => uint256) public balances;

    /// @dev Initialization method
    /// @param rewardsToken rewardsToken address
    /// @param stakingToken stakingToken address
	constructor(address rewardsToken,
                address stakingToken) public {
		_rewardsToken = rewardsToken;
        _stakingToken = stakingToken;
		_governance = msg.sender;
    }

    //---------modifier---------

    modifier onlyGovernance() {
        require(msg.sender == _governance, "Log:InsurancePool:!gov");
        _;
    }

    modifier updateReward(address account) {
        _rewardPerTokenStored = rewardPerToken();
        _lastUpdateBlock = getBlock();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }
        _;
    }

    //---------view---------

    function getBalance(address user) override external view returns(uint256) {
    	return balances[user];
    }

    function getBlock() public view returns(uint256) {
    	uint256 nowBlock = block.number;
    	if (nowBlock > _endBlock) {
    		return _endBlock;
    	}
    	return nowBlock;
    }

    function accrued() public view returns (uint256) {
        if (_lastUpdateBlock == 0) {
            return 0;
        }
        return (getBlock() - _lastUpdateBlock) * _rewardRate;
    }

    function earned(address account) public view returns (uint256) {
        return balances[account] * (_rewardPerTokenStored - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    function estimatedIncome(address account) public view returns (uint256) {
        return balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return _rewardPerTokenStored;
        }
        return _rewardPerTokenStored + accrued() * 1e18 / _totalSupply;
    }

    //---------governance----------

    function setGovernance(address add) external onlyGovernance {
    	_governance = add; 
    }

    function addToken(address rewardsToken, uint256 tokenAmount, address from, uint256 rewardRate) external onlyGovernance {
    	TransferHelper.safeTransferFrom(rewardsToken, from, address(this), tokenAmount);
    	_lastUpdateBlock = block.number;
        _rewardRate = rewardRate;
    	_endBlock = tokenAmount / rewardRate + _lastUpdateBlock;
    }

    function subToken(address token, uint256 amount, address to) external onlyGovernance {
        TransferHelper.safeTransfer(token, to, amount);
    }

    function setEndBlock(uint256 blockNum) external onlyGovernance {
    	_endBlock = blockNum;
    }

    function setLastUpdateBlock(uint256 blockNum) external onlyGovernance {
    	_lastUpdateBlock = blockNum;
    }

    //---------transaction---------

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Log:LPStakingMiningPool:!0");
    	_totalSupply = _totalSupply - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        TransferHelper.safeTransferFrom(_stakingToken, msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Log:LPStakingMiningPool:!0");
        _totalSupply = _totalSupply - amount;
        balances[msg.sender] = balances[msg.sender] - amount;
    	TransferHelper.safeTransfer(_stakingToken, msg.sender, amount);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _safeAsetTransfer(msg.sender, reward);
        }
    }

    function _safeAsetTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 asetBal = IERC20(_rewardsToken).balanceOf(address(this));
        if (_amount > asetBal) {
            _amount = asetBal;
        }
        TransferHelper.safeTransfer(_rewardsToken, _to, _amount); // allow zero amount
        return _amount;
    }
}