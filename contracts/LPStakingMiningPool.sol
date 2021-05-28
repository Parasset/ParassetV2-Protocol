// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "./lib/SafeMath.sol";
import './lib/SafeERC20.sol';
import './lib/TransferHelper.sol';
import "./lib/ReentrancyGuard.sol";
import "./iface/ILPStakingMiningPool.sol";

contract LPStakingMiningPool is ReentrancyGuard, ILPStakingMiningPool {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	// ASET
    address public _rewardsToken;
    // PA
    address public _stakingToken;
    address public _governance;

    uint256 public _lastUpdateBlock;
    uint256 public _rewardPerTokenStored;
    uint256 public _rewardRate;
    uint256 public _totalSupply;
    uint256 public _endBlock;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;

	constructor(address rewardsToken,
                address stakingToken) public {
		_rewardsToken = rewardsToken;
        _stakingToken = stakingToken;
		_governance = msg.sender;
    }

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

    function setGovernance(address add) external onlyGovernance {
    	_governance = add; 
    }

    function addToken(address rewardsToken, uint256 tokenAmount, address from, uint256 rewardRate) external onlyGovernance {
    	ERC20(rewardsToken).safeTransferFrom(from, address(this), tokenAmount);
    	_lastUpdateBlock = block.number;
    	_endBlock = tokenAmount.div(rewardRate).add(_lastUpdateBlock);
    }

    function subToken(address token, uint256 amount, address to) external onlyGovernance {
        ERC20(token).safeTransfer(to, amount);
    }

    function setEndBlock(uint256 blockNum) external onlyGovernance {
    	_endBlock = blockNum;
    }

    function setLastUpdateBlock(uint256 blockNum) external onlyGovernance {
    	_lastUpdateBlock = blockNum;
    }

    function accrued() public view returns (uint256) {
        if (_lastUpdateBlock == 0) {
            return 0;
        }
        return getBlock().sub(_lastUpdateBlock).mul(_rewardRate);
    }

    function earned(address account) public view returns (uint256) {
        return balances[account].mul(_rewardPerTokenStored.sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function estimatedIncome(address account) public view returns (uint256) {
        return balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return _rewardPerTokenStored;
        }
        return _rewardPerTokenStored.add(accrued().mul(1e18).div(_totalSupply));
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Log:LPStakingMiningPool:!0");
    	_totalSupply = _totalSupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        TransferHelper.safeTransferFrom(_stakingToken, msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Log:LPStakingMiningPool:!0");
        _totalSupply = _totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
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
        uint256 asetBal = ERC20(_rewardsToken).balanceOf(address(this));
        if (_amount > asetBal) {
            _amount = asetBal;
        }
        TransferHelper.safeTransfer(_rewardsToken, _to, _amount); // allow zero amount
        return _amount;
    }
}