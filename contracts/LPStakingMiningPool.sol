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

    address public rewardsToken; // ASET
    address public stakingToken; // PA
    address public governance;

    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;
    uint256 public _totalSupply;
    uint256 public endBlock;
    uint8 public flag = 0;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public _balances;

    // mapping(address => UserInfo) public userMapping;
    // struct UserInfo {
    //     uint80 userRewardPerTokenPaid;
    //     uint88 rewards;
    //     uint88 _balances;
    // }

	constructor(address _rewardsToken,
                address _stakingToken) public {
		rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
		governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Log:InsurancePool:!gov");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = getBlock();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function getBalance(address user) override external view returns(uint256) {
    	return _balances[user];
    }

    function getBlock() public view returns(uint256) {
    	uint256 nowBlock = block.number;
    	if (nowBlock > endBlock) {
    		return endBlock;
    	}
    	return nowBlock;
    }

    function accrued() public view returns (uint256) {
        if (lastUpdateBlock == 0) {
            return 0;
        }
        return getBlock().sub(lastUpdateBlock).mul(rewardRate);
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerTokenStored.sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function estimatedIncome(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(accrued().mul(1e18).div(_totalSupply));
    }

    function addToken(address _rewardsToken, uint256 tokenAmount, address _from, uint256 _rewardRate) external onlyGovernance {
    	ERC20(_rewardsToken).safeTransferFrom(_from, address(this), tokenAmount);
    	lastUpdateBlock = block.number;
    	endBlock = tokenAmount.div(_rewardRate).add(lastUpdateBlock);
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Log:LPStakingMiningPool:!0");
    	_totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        TransferHelper.safeTransferFrom(stakingToken, msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Log:LPStakingMiningPool:!0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    	TransferHelper.safeTransfer(stakingToken, msg.sender, amount);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 transferred = _safeAsetTransfer(msg.sender, reward);
        }
    }

    function _safeAsetTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 asetBal = ERC20(rewardsToken).balanceOf(address(this));
        if (_amount > asetBal) {
            _amount = asetBal;
        }
        TransferHelper.safeTransfer(rewardsToken, _to, _amount); // allow zero amount
        return _amount;
    }

    // function addAset(address token, uint256 amount) public onlyGovernance {
    // 	require(now < startTime, "Log:LPStakingMiningPool:!time");
    // 	ERC20(token).safeTransferFrom(address(msg.sender), address(this), amount);
    //     if (token == rewardsToken) {
    //         allAset = allAset.add(amount);
    //     }
    // }

    // function subAset(address token, uint256 amount, address to) public onlyGovernance {
    //     ERC20(token).safeTransfer(to, amount);
    //     if (token == rewardsToken) {
    //         allAset = allAset.sub(amount);
    //     }
    // }

}