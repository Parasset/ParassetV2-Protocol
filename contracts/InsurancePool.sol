// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./iface/IInsurancePool.sol";
import "./iface/IParasset.sol";
import "./iface/ILPStakingMiningPool.sol";
import './lib/TransferHelper.sol';
import "./ParassetBase.sol";

contract InsurancePool is ParassetBase, IInsurancePool {

    // negative account funds
    uint256 public _insNegative;
    // latest redemption time
    uint256 public _latestTime;
    // status
    uint8 public _flag;      // = 0: pause
                             // = 1: active
                             // = 2: redemption only
    // user address => freeze LP data
    mapping(address => Frozen) frozenIns;
    // user address => balances
    mapping(address => uint256) balances;
    // trom address => to address => amount
    mapping(address => mapping (address => uint256)) allowed;
    struct Frozen {
        // frozen quantity
        uint256 amount;
        // freezing time                      
        uint256 time;                           
    }
    // pToken address
    address public _pTokenAddress;
    // underlyingToken address
    address public _underlyingTokenAddress;
    // mortgagePool address
    address public _mortgagePool;
	// redemption cycle, 2 days
	uint256 public _redemptionCycle;
	// redemption duration, 7 days
	uint256 public _waitCycle;
    // rate(2/1000)
    uint256 public _feeRate;
    // is ETH insPool
    bool public _ethIns;

    // staking address
    ILPStakingMiningPool lpStakingMiningPool;

    // ERC20 - totalSupply
    uint256 public totalSupply;
    // ERC20 - name                                     
    string public name;
    // ERC20 - symbol
    string public symbol;
    // ERC20 - decimals
    uint8 public decimals;

    event Destroy(uint256 amount, address account);
    event Issuance(uint256 amount, address account);
    event Negative(uint256 amount, uint256 allValue);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initialize(address governance) public override {
        super.initialize(governance);
        _redemptionCycle = 2 days;
        _waitCycle = 7 days;
        _feeRate = 2;
        _ethIns = false;
        totalSupply = 0;
        name = "";
        symbol = "";
        decimals = 18;
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

    /// @dev View the total LP
    /// @return total LP
    function getTotalSupply() external view returns(uint256) {
        return totalSupply;
    }

    /// @dev View the lpStakingMiningPool address
    /// @return lpStakingMiningPool address
    function getLPStakingMiningPool() external view returns(address) {
        return address(lpStakingMiningPool);
    }

    /// @dev View the all lp 
    /// @return all lp 
    function getAllLP(address user) public view returns(uint256) {
        return balances[user] + lpStakingMiningPool.getBalance(address(this), user);
    }

    /// @dev View the personal LP
    /// @param add user address
    /// @return personal LP
    function getBalances(address add) external view returns(uint256) {
        return balances[add];
    }

    /// @dev View redemption period, next time
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTime() external view returns(uint256 startTime, uint256 endTime) {
        uint256 time = _latestTime;
        if (block.timestamp > time) {
            uint256 subTime = (block.timestamp - time) / _waitCycle;
            startTime = time + (_waitCycle * (1 + subTime));
        } else {
            startTime = time;
        }
        endTime = startTime + _redemptionCycle;
    }

    /// @dev View redemption period, this period
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTimeFront() external view returns(uint256 startTime, uint256 endTime) {
        uint256 time = _latestTime;
        if (block.timestamp > time) {
            uint256 subTime = (block.timestamp - time) / _waitCycle;
            startTime = time + (_waitCycle * subTime);
        } else {
            startTime = time - _waitCycle;
        }
        endTime = startTime + _redemptionCycle;
    }

    /// @dev View frozen LP and unfreeze time
    /// @param add user address
    /// @return frozen LP
    /// @return unfreeze time
    function getFrozenIns(address add) external view returns(uint256, uint256) {
        Frozen memory frozenInfo = frozenIns[add];
        return (frozenInfo.amount, frozenInfo.time);
    }

    /// @dev View frozen LP and unfreeze time, real time
    /// @param add user address
    /// @return frozen LP
    function getFrozenInsInTime(address add) external view returns(uint256) {
        Frozen memory frozenInfo = frozenIns[add];
        if (block.timestamp > frozenInfo.time) {
            return 0;
        }
        return frozenInfo.amount;
    }

    /// @dev View redeemable LP, real time
    /// @param add user address
    /// @return redeemable LP
    function getRedemptionAmount(address add) external view returns (uint256) {
        Frozen memory frozenInfo = frozenIns[add];
        uint256 balanceSelf = balances[add];
        if (block.timestamp > frozenInfo.time) {
            return balanceSelf;
        } else {
            return balanceSelf - frozenInfo.amount;
        }
    }

    //---------governance----------

    /// @dev Set token name
    /// @param _name token name
    /// @param _symbol token symbol
    function setTokenInfo(string memory _name, string memory _symbol) external onlyGovernance {
        name = _name;
        symbol = _symbol;
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
        lpStakingMiningPool = ILPStakingMiningPool(add);
    }

    /// @dev Set the latest redemption time
    function setLatestTime() external onlyGovernance {
        _latestTime = block.timestamp + _waitCycle;
    }
    function setLatestTime(uint256 num) external onlyGovernance {
        _latestTime = num;
    }

    /// @dev Set the rate
    function setFeeRate(uint256 num) external onlyGovernance {
        _feeRate = num;
    }

    /// @dev Set redemption cycle
    function setRedemptionCycle(uint256 num) external onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _redemptionCycle = num * 1 days;
    }

    /// @dev Set redemption duration
    function setWaitCycle(uint256 num) external onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _waitCycle = num * 1 days;
    }

    /// @dev Set the underlying asset and ptoken mapping and
    /// @param uToken underlying asset address
    /// @param pToken ptoken address
    function setInfo(address uToken, address pToken) external onlyGovernance {
        _underlyingTokenAddress = uToken;
        _pTokenAddress = pToken;
    }

    function setETHIns(bool isETHIns) external onlyGovernance {
        _ethIns = isETHIns;
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
        TransferHelper.safeTransferFrom(_pTokenAddress, address(msg.sender), address(this), amount);

        // Calculate the amount of transferred underlying asset
        uint256 uTokenAmount = getDecimalConversion(_pTokenAddress, amount - fee, _underlyingTokenAddress);
        require(uTokenAmount > 0, "Log:InsurancePool:!uTokenAmount");

        // Transfer out underlying asset
    	if (_ethIns) {
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
    	if (_ethIns) {
            // The underlying asset is ETH
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
    	} else {
            // The underlying asset is ERC20
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            TransferHelper.safeTransferFrom(_underlyingTokenAddress, address(msg.sender), address(this), amount);
    	}

        // Calculate the amount of transferred ptokens
        uint256 pTokenAmount = getDecimalConversion(_underlyingTokenAddress, amount - fee, _pTokenAddress);
        require(pTokenAmount > 0, "Log:InsurancePool:!pTokenAmount");

        // Transfer out ptoken
        uint256 pTokenBalance = IERC20(_pTokenAddress).balanceOf(address(this));
        if (pTokenBalance < pTokenAmount) {
            // Insufficient ptoken balance,
            uint256 subNum = pTokenAmount - pTokenBalance;
            IParasset(_pTokenAddress).issuance(subNum, address(this));
            _insNegative = _insNegative + subNum;
        }
        TransferHelper.safeTransfer(_pTokenAddress, address(msg.sender), pTokenAmount);
    }

    /// @dev Subscribe for insurance
    /// @param amount amount of underlying asset
    function subscribeIns(uint256 amount) public payable whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Update redemption time
    	updateLatestTime();

        // Thaw LP
    	Frozen storage frozenInfo = frozenIns[address(msg.sender)];
    	if (block.timestamp > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}

        // ptoken balance 
    	uint256 pTokenBalance = IERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_ethIns) {
            // The amount of ETH involved in the calculation does not include the transfer in this time
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
            tokenBalance = address(this).balance - amount;
    	} else {
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            // Underlying asset conversion 18 decimals
            tokenBalance = getDecimalConversion(_underlyingTokenAddress, IERC20(_underlyingTokenAddress).balanceOf(address(this)), _pTokenAddress);
    	}

        // Calculate LP
    	uint256 insAmount = 0;
    	uint256 insTotal = totalSupply;
        uint256 allBalance = tokenBalance - pTokenBalance;
    	if (insTotal != 0) {
            // Insurance pool assets must be greater than 0
            require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
            uint256 allValue = allBalance - _insNegative;
    		insAmount = getDecimalConversion(_underlyingTokenAddress, amount, _pTokenAddress) * insTotal / allValue;
    	} else {
            // The initial net value is 1
            insAmount = getDecimalConversion(_underlyingTokenAddress, amount, _pTokenAddress);
        }

    	// Transfer to the underlying asset(ERC20)
    	if (!_ethIns) {
    		require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            TransferHelper.safeTransferFrom(_underlyingTokenAddress, address(msg.sender), address(this), amount);
    	}

    	// Additional LP issuance
    	issuance(insAmount, address(msg.sender));

    	// Freeze insurance LP
    	frozenInfo.amount = frozenInfo.amount + insAmount;
    	frozenInfo.time = _latestTime + _waitCycle;
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
    	require(block.timestamp >= tokenTime - _waitCycle && block.timestamp <= tokenTime - _waitCycle + _redemptionCycle, "Log:InsurancePool:!time");

        // Thaw LP
    	Frozen storage frozenInfo = frozenIns[address(msg.sender)];
    	if (block.timestamp > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}
    	
        // ptoken balance
    	uint256 pTokenBalance = IERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_ethIns) {
            tokenBalance = address(this).balance;
    	} else {
    		tokenBalance = getDecimalConversion(_underlyingTokenAddress, IERC20(_underlyingTokenAddress).balanceOf(address(this)), _pTokenAddress);
    	}

        // Insurance pool assets must be greater than 0
        uint256 allBalance = tokenBalance + pTokenBalance;
        require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
        // Calculated amount of assets
    	uint256 allValue = allBalance - _insNegative;
    	uint256 insTotal = totalSupply;
    	uint256 underlyingAmount = amount * allValue / insTotal;

        // Destroy LP
        destroy(amount, address(msg.sender));
        // Judgment to freeze LP
        require(getAllLP(address(msg.sender)) >= frozenInfo.amount, "Log:InsurancePool:frozen");
    	
    	// Transfer out assets, priority transfer of the underlying assets, if the underlying assets are insufficient, transfer ptoken
    	if (_ethIns) {
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
    function destroyPToken(uint256 amount) override public onlyMortgagePool {
    	IParasset pErc20 = IParasset(_pTokenAddress);
    	uint256 pTokenBalance = pErc20.balanceOf(address(this));
    	if (pTokenBalance >= amount) {
    		pErc20.destroy(amount, address(this));
    	} else {
    		pErc20.destroy(pTokenBalance, address(this));
    		// 记录负账户
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
    		uint256 subTime = (block.timestamp - time) / _waitCycle;
    		_latestTime = time + (_waitCycle * (1 + subTime));
    	}
    }

    /// @dev Destroy LP
    /// @param amount quantity destroyed
    /// @param account destroy address
    function destroy(uint256 amount, 
                     address account) private {
        require(balances[account] >= amount, "Log:InsurancePool:!destroy");
        balances[account] = balances[account] - amount;
        totalSupply = totalSupply - amount;
        emit Destroy(amount, account);
    }

    /// @dev Additional LP issuance
    /// @param amount additional issuance quantity
    /// @param account additional issuance address
    function issuance(uint256 amount, 
                      address account) private {
        balances[account] = balances[account] + amount;
        totalSupply = totalSupply + amount;
        emit Issuance(amount, account);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender] - value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender] - subtractedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        // // Update redemption time
        // updateLatestTime();

        // // Thaw LP
        // Frozen storage frozenInfo = frozenIns[address(msg.sender)];
        // if (block.timestamp > frozenInfo.time) {
        //     frozenInfo.amount = 0;
        // }

        balances[from] = balances[from] - value;
        balances[to] = balances[to] + value;
        emit Transfer(from, to, value);

        // if (to != address(lpStakingMiningPool)) {
        //     require(getAllLP(address(msg.sender)) >= frozenInfo.amount, "Log:InsurancePool:frozen");
        // }
    }

    function addETH() public payable {}

    function addToken(address tokenAddress, uint256 amount) public {
        TransferHelper.safeTransferFrom(tokenAddress, address(msg.sender), address(this), amount);
    }

}