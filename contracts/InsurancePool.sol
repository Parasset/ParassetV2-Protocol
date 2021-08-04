// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./iface/IInsurancePool.sol";
import "./iface/IParasset.sol";
import "./iface/ILPStakingMiningPool.sol";
import './lib/TransferHelper.sol';
import "./ParassetBase.sol";
import "./ParassetERC20.sol";

contract InsurancePool is ParassetBase, IInsurancePool, ParassetERC20 {

    // negative account funds
    uint256 public _insNegative;
    // latest redemption time
    uint256 public _latestTime;
    // status
    uint8 public _flag;      // = 0: pause
                             // = 1: active
                             // = 2: redemption only
    // user address => freeze LP data
    mapping(address => Frozen) _frozenIns;
    struct Frozen {
        // frozen quantity
        uint256 amount;
        // freezing time                      
        uint256 time;                           
    }
    // pToken address
    address public _pTokenAddress;
    // redemption cycle, 2 days
	uint96 public _redemptionCycle;
    // underlyingToken address
    address public _underlyingTokenAddress;
    // redemption duration, 7 days
	uint96 public _waitCycle;
    // mortgagePool address
    address public _mortgagePool;
    // rate(2/1000)
    uint96 public _feeRate;

    uint constant MINIMUM_LIQUIDITY = 1e9; 

    // staking address
    ILPStakingMiningPool _lpStakingMiningPool;

    event Negative(uint256 amount, uint256 allValue);

    function initialize(address governance) public override {
        super.initialize(governance);
        _redemptionCycle = 15 minutes;
        _waitCycle = 30 minutes;
        _feeRate = 2;
        _totalSupply = 0;
    }

	//---------modifier---------

    modifier onlyMortgagePool() {
        require(msg.sender == address(_mortgagePool), "Log:InsurancePool:!mortgagePool");
        _;
    }

    modifier whenActive() {
        require(_flag == 1, "Log:InsurancePool:!active");
        _;
    }

    modifier redemptionOnly() {
        require(_flag != 0, "Log:InsurancePool:!0");
        _;
    }

    //---------view---------

    /// @dev View the lpStakingMiningPool address
    /// @return lpStakingMiningPool address
    function getLPStakingMiningPool() external view returns(address) {
        return address(_lpStakingMiningPool);
    }

    /// @dev View the all lp 
    /// @return all lp 
    function getAllLP(address user) public view returns(uint256) {
        return _balances[user] + _lpStakingMiningPool.getBalance(address(this), user);
    }

    /// @dev View redemption period, next time
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTime() external view returns(uint256 startTime, uint256 endTime) {
        uint256 time = _latestTime;
        if (block.timestamp > time) {
            uint256 subTime = (block.timestamp - time) / uint256(_waitCycle);
            startTime = time + (uint256(_waitCycle) * (1 + subTime));
        } else {
            startTime = time;
        }
        endTime = startTime + uint256(_redemptionCycle);
    }

    /// @dev View redemption period, this period
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTimeFront() external view returns(uint256 startTime, uint256 endTime) {
        uint256 time = _latestTime;
        if (block.timestamp > time) {
            uint256 subTime = (block.timestamp - time) / uint256(_waitCycle);
            startTime = time + (uint256(_waitCycle) * subTime);
        } else {
            startTime = time - uint256(_waitCycle);
        }
        endTime = startTime + uint256(_redemptionCycle);
    }

    /// @dev View frozen LP and unfreeze time
    /// @param add user address
    /// @return frozen LP
    /// @return unfreeze time
    function getFrozenIns(address add) external view returns(uint256, uint256) {
        Frozen memory frozenInfo = _frozenIns[add];
        return (frozenInfo.amount, frozenInfo.time);
    }

    /// @dev View frozen LP and unfreeze time, real time
    /// @param add user address
    /// @return frozen LP
    function getFrozenInsInTime(address add) external view returns(uint256) {
        Frozen memory frozenInfo = _frozenIns[add];
        if (block.timestamp > frozenInfo.time) {
            return 0;
        }
        return frozenInfo.amount;
    }

    /// @dev View redeemable LP, real time
    /// @param add user address
    /// @return redeemable LP
    function getRedemptionAmount(address add) external view returns (uint256) {
        Frozen memory frozenInfo = _frozenIns[add];
        uint256 balanceSelf = _balances[add];
        if (block.timestamp > frozenInfo.time) {
            return balanceSelf;
        } else {
            return balanceSelf - frozenInfo.amount;
        }
    }

    //---------governance----------

    /// @dev Set token name
    /// @param name token name
    /// @param symbol token symbol
    function setTokenInfo(string memory name, string memory symbol) external onlyGovernance {
        _name = name;
        _symbol = symbol;
    }

    /// @dev Set contract status
    /// @param num 0: pause, 1: active, 2: redemption only
    function setFlag(uint8 num) external onlyGovernance {
        _flag = num;
    }

    /// @dev Set mortgage pool address
    function setMortgagePool(address add) external onlyGovernance {
    	_mortgagePool = add;
    }

    /// @dev Set the staking contract address
    function setLPStakingMiningPool(address add) external onlyGovernance {
        _lpStakingMiningPool = ILPStakingMiningPool(add);
    }

    /// @dev Set the latest redemption time
    function setLatestTime(uint256 num) external onlyGovernance {
        _latestTime = num;
    }

    /// @dev Set the rate
    function setFeeRate(uint96 num) external onlyGovernance {
        _feeRate = num;
    }

    /// @dev Set redemption cycle
    function setRedemptionCycle(uint256 num) external onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _redemptionCycle = uint96(num * 1 days);
    }

    /// @dev Set redemption duration
    function setWaitCycle(uint256 num) external onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _waitCycle = uint96(num * 1 days);
    }

    /// @dev Set the underlying asset and ptoken mapping and
    /// @param uToken underlying asset address
    /// @param pToken ptoken address
    function setInfo(address uToken, address pToken) external onlyGovernance {
        _underlyingTokenAddress = uToken;
        _pTokenAddress = pToken;
    }

    function test_insNegative(uint256 amount) external onlyGovernance {
        _insNegative = amount;
    }

    //---------transaction---------

    /// @dev Exchange: ptoken exchanges the underlying asset
    /// @param amount amount of ptoken
    function exchangePTokenToUnderlying(uint256 amount) public whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Calculate the fee
    	uint256 fee = amount * _feeRate / 1000;

        // Transfer to the ptoken
        address pTokenAddress = _pTokenAddress;
        TransferHelper.safeTransferFrom(pTokenAddress, address(msg.sender), address(this), amount);

        // Calculate the amount of transferred underlying asset
        uint256 uTokenAmount = getDecimalConversion(pTokenAddress, amount - fee, _underlyingTokenAddress);
        require(uTokenAmount > 0, "Log:InsurancePool:!uTokenAmount");

        // Transfer out underlying asset
    	if (_underlyingTokenAddress == address(0x0)) {
            TransferHelper.safeTransferETH(address(msg.sender), uTokenAmount);
    	} else {
            TransferHelper.safeTransfer(_underlyingTokenAddress, address(msg.sender), uTokenAmount);
    	}

    	// Eliminate negative ledger
        eliminate();
    }

    /// @dev Exchange: underlying asset exchanges the ptoken
    /// @param amount amount of underlying asset
    function exchangeUnderlyingToPToken(uint256 amount) public payable whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Calculate the fee
    	uint256 fee = amount * _feeRate / 1000;

        // Transfer to the underlying asset
    	if (_underlyingTokenAddress == address(0x0)) {
            // The underlying asset is ETH
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
    	} else {
            // The underlying asset is ERC20
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            TransferHelper.safeTransferFrom(_underlyingTokenAddress, address(msg.sender), address(this), amount);
    	}

        // Calculate the amount of transferred ptokens
        uint256 pTokenAmount = getDecimalConversion(_underlyingTokenAddress, amount - fee, address(0x0));
        require(pTokenAmount > 0, "Log:InsurancePool:!pTokenAmount");

        // Transfer out ptoken
        address pTokenAddress = _pTokenAddress;
        uint256 pTokenBalance = IERC20(pTokenAddress).balanceOf(address(this));
        if (pTokenBalance < pTokenAmount) {
            // Insufficient ptoken balance,
            uint256 subNum = pTokenAmount - pTokenBalance;
            IParasset(pTokenAddress).issuance(subNum, address(this));
            _insNegative = _insNegative + subNum;
        }
        TransferHelper.safeTransfer(pTokenAddress, address(msg.sender), pTokenAmount);
    }

    /// @dev Subscribe for insurance
    /// @param amount amount of underlying asset
    function subscribeIns(uint256 amount) public payable whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Update redemption time
    	updateLatestTime();

        // Thaw LP
    	Frozen storage frozenInfo = _frozenIns[address(msg.sender)];
    	if (block.timestamp > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}

        // ptoken balance 
    	uint256 pTokenBalance = IERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_underlyingTokenAddress == address(0x0)) {
            // The amount of ETH involved in the calculation does not include the transfer in this time
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
            tokenBalance = address(this).balance - amount;
    	} else {
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            // Underlying asset conversion 18 decimals
            tokenBalance = getDecimalConversion(_underlyingTokenAddress, IERC20(_underlyingTokenAddress).balanceOf(address(this)), address(0x0));
    	}

        // Calculate LP
    	uint256 insAmount = 0;
    	uint256 insTotal = _totalSupply;
        uint256 allBalance = tokenBalance + pTokenBalance;
    	if (insTotal != 0) {
            // Insurance pool assets must be greater than 0
            require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
            uint256 allValue = allBalance - _insNegative;
    		insAmount = getDecimalConversion(_underlyingTokenAddress, amount, address(0x0)) * insTotal / allValue;
    	} else {
            // The initial net value is 1
            insAmount = getDecimalConversion(_underlyingTokenAddress, amount, address(0x0)) - MINIMUM_LIQUIDITY;
            _issuance(MINIMUM_LIQUIDITY, address(0x0));
        }

    	// Transfer to the underlying asset(ERC20)
    	if (_underlyingTokenAddress != address(0x0)) {
    		require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            TransferHelper.safeTransferFrom(_underlyingTokenAddress, address(msg.sender), address(this), amount);
    	}

    	// Additional LP issuance
    	_issuance(insAmount, address(msg.sender));

    	// Freeze insurance LP
    	frozenInfo.amount = frozenInfo.amount + insAmount;
    	frozenInfo.time = _latestTime + uint256(_waitCycle);
    }

    /// @dev Redemption insurance
    /// @param amount redemption LP
    function redemptionIns(uint256 amount) public redemptionOnly nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Update redemption time
    	updateLatestTime();

        // Judging the redemption time
        uint256 tokenTime = _latestTime;
    	require(block.timestamp >= tokenTime - uint256(_waitCycle) && block.timestamp <= tokenTime - uint256(_waitCycle) + uint256(_redemptionCycle), "Log:InsurancePool:!time");

        // Thaw LP
    	Frozen storage frozenInfo = _frozenIns[address(msg.sender)];
    	if (block.timestamp > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}
    	
        // ptoken balance
    	uint256 pTokenBalance = IERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_underlyingTokenAddress == address(0x0)) {
            tokenBalance = address(this).balance;
    	} else {
    		tokenBalance = getDecimalConversion(_underlyingTokenAddress, IERC20(_underlyingTokenAddress).balanceOf(address(this)), address(0x0));
    	}

        // Insurance pool assets must be greater than 0
        uint256 allBalance = tokenBalance + pTokenBalance;
        require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
        // Calculated amount of assets
    	uint256 allValue = allBalance - _insNegative;
    	uint256 insTotal = _totalSupply;
    	uint256 underlyingAmount = amount * allValue / insTotal;

        // Destroy LP
        _destroy(amount, address(msg.sender));
        // Judgment to freeze LP
        require(getAllLP(address(msg.sender)) >= frozenInfo.amount, "Log:InsurancePool:frozen");
    	
    	// Transfer out assets, priority transfer of the underlying assets, if the underlying assets are insufficient, transfer ptoken
    	if (_underlyingTokenAddress == address(0x0)) {
            // ETH
            if (tokenBalance >= underlyingAmount) {
                TransferHelper.safeTransferETH(address(msg.sender), underlyingAmount);
            } else {
                TransferHelper.safeTransferETH(address(msg.sender), tokenBalance);
                TransferHelper.safeTransfer(_pTokenAddress, address(msg.sender), underlyingAmount - tokenBalance);
            }
    	} else {
            // ERC20
            if (tokenBalance >= underlyingAmount) {
                TransferHelper.safeTransfer(_underlyingTokenAddress, address(msg.sender), getDecimalConversion(_pTokenAddress, underlyingAmount, _underlyingTokenAddress));
            } else {
                TransferHelper.safeTransfer(_underlyingTokenAddress, address(msg.sender), getDecimalConversion(_pTokenAddress, tokenBalance, _underlyingTokenAddress));
                TransferHelper.safeTransfer(_pTokenAddress, address(msg.sender), underlyingAmount - tokenBalance);
            }
    	}
    }

    /// @dev Destroy ptoken, update negative ledger
    /// @param amount quantity destroyed
    function destroyPToken(uint256 amount) public override onlyMortgagePool {
    	IParasset pErc20 = IParasset(_pTokenAddress);
    	uint256 pTokenBalance = pErc20.balanceOf(address(this));
    	if (pTokenBalance >= amount) {
    		pErc20.destroy(amount, address(this));
    	} else {
    		pErc20.destroy(pTokenBalance, address(this));
    		// Increase negative ledger
            uint256 subAmount = amount - pTokenBalance;
    		_insNegative = _insNegative + subAmount;
            emit Negative(subAmount, _insNegative);
    	}
    }

    /// @dev Clear negative books
    function eliminate() override public {
    	IParasset pErc20 = IParasset(_pTokenAddress);
        // negative ledger
    	uint256 negative = _insNegative;
        // ptoken balance
    	uint256 pTokenBalance = pErc20.balanceOf(address(this)); 
    	if (negative > 0 && pTokenBalance > 0) {
    		if (negative >= pTokenBalance) {
                // Increase negative ledger
                pErc20.destroy(pTokenBalance, address(this));
    			_insNegative = _insNegative - pTokenBalance;
                emit Negative(pTokenBalance, _insNegative);
    		} else {
                // negative ledger = 0
                pErc20.destroy(negative, address(this));
    			_insNegative = 0;
                emit Negative(negative, _insNegative);
    		}
    	}
    }

    /// @dev Update redemption time
    function updateLatestTime() public {
        uint256 time = _latestTime;
    	if (block.timestamp > time) {
    		uint256 subTime = (block.timestamp - time) / uint256(_waitCycle);
    		_latestTime = time + (uint256(_waitCycle) * (1 + subTime));
    	}
    }

    /// @dev Destroy LP
    /// @param amount quantity destroyed
    /// @param account destroy address
    function _destroy(
        uint256 amount, 
        address account
    ) private {
        require(_balances[account] >= amount, "Log:InsurancePool:!destroy");
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        // emit Destroy(amount, account);
        emit Transfer(account, address(0x0), amount);
    }

    /// @dev Additional LP issuance
    /// @param amount additional issuance quantity
    /// @param account additional issuance address
    function _issuance(
        uint256 amount, 
        address account
    ) private {
        _balances[account] = _balances[account] + amount;
        _totalSupply = _totalSupply + amount;
        // emit Issuance(amount, account);
        emit Transfer(address(0x0), account, amount);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Update redemption time
        updateLatestTime();

        // Thaw LP
        Frozen storage frozenInfo = _frozenIns[sender];
        if (block.timestamp > frozenInfo.time) {
            frozenInfo.amount = 0;
        }

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        if (recipient != address(_lpStakingMiningPool)) {
            require(getAllLP(sender) >= frozenInfo.amount, "Log:InsurancePool:frozen");
        }
    }

    /// The insurance pool penetrates the warehouse, and external assets are added to the insurance pool.
    function addETH() external payable {}

}