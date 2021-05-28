// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "./iface/IInsurancePool.sol";
import "./iface/IParasset.sol";
import "./iface/IPTokenFactory.sol";
import "./iface/ILPStakingMiningPool.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/SafeMath.sol";
import './lib/TransferHelper.sol';
import './lib/SafeERC20.sol';

contract InsurancePool is ReentrancyGuard, IInsurancePool {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	// Governance address
	address public _governance;
	// negative account funds
	uint256 public _insNegative;
	// latest redemption time
    uint256 public _latestTime;
    // Status
    uint8 public _flag;      // = 0: pause
                            // = 1: active
                            // = 2: redemption only
    // User address => Freeze LP data
    mapping(address => Frozen) frozenIns;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    struct Frozen {
        uint256 amount;                         // Frozen quantity
        uint256 time;                           // Freezing time
    }
    address public _pTokenAddress;
    address public _underlyingTokenAddress;
    address public _mortgagePool;
	// Redemption cycle, 2 days
	uint256 public _redemptionCycle = 2 days;
	// Redemption duration, 7 days
	uint256 public _waitCycle = 7 days;
    // Rate(2/1000)
    uint256 public _feeRate = 2;
    bool public _ethIns = false;

    // PTokenFactory address
    IPTokenFactory pTokenFactory;
    // Staking address
    ILPStakingMiningPool lpStakingMiningPool;
    
    uint256 public totalSupply = 0;                                        
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 18;

    event Destroy(uint256 amount, address account);
    event Issuance(uint256 amount, address account);
    event Negative(uint256 amount, uint256 allValue);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Initialization method
    /// @param factoryAddress PTokenFactory address
	constructor (address factoryAddress, string memory _name, string memory _symbol) public {
        pTokenFactory = IPTokenFactory(factoryAddress);
        _governance = pTokenFactory.getGovernance();
        name = _name;
        symbol = _symbol;
        _flag = 0;
    }

	//---------modifier---------

    modifier onlyGovernance() {
        require(msg.sender == _governance, "Log:InsurancePool:!gov");
        _;
    }

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

    /// @dev View governance address
    /// @return governance address
    function getGovernance() external view returns(address) {
        return _governance;
    }

    /// @dev View total LP
    /// @return total LP
    function getTotalSupply() external view returns(uint256) {
        return totalSupply;
    }

    function getPTokenFactory() external view returns(address) {
        return address(pTokenFactory);
    }

    function getLPStakingMiningPool() external view returns(address) {
        return address(lpStakingMiningPool);
    }

    function getAllLP(address user) public view returns(uint256) {
        return balances[user].add(lpStakingMiningPool.getBalance(user));
    }

    /// @dev View personal LP
    /// @param add user address
    /// @return personal LP
    function getBalances(address add) external view returns(uint256) {
        return balances[add];
    }

    /// @dev View redemption period, next time
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTime() external view returns(uint256 startTime, 
                                                                    uint256 endTime) {
        uint256 time = _latestTime;
        if (now > time) {
            uint256 subTime = now.sub(time).div(_waitCycle);
            startTime = time.add(_waitCycle.mul(uint256(1).add(subTime)));
        } else {
            startTime = time;
        }
        endTime = startTime.add(_redemptionCycle);
    }

    /// @dev View redemption period, this period
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTimeFront() external view returns(uint256 startTime, 
                                                                         uint256 endTime) {
        uint256 time = _latestTime;
        if (now > time) {
            uint256 subTime = now.sub(time).div(_waitCycle);
            startTime = time.add(_waitCycle.mul(subTime));
        } else {
            startTime = time.sub(_waitCycle);
        }
        endTime = startTime.add(_redemptionCycle);
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
        if (now > frozenInfo.time) {
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
        if (now > frozenInfo.time) {
            return balanceSelf;
        } else {
            return balanceSelf.sub(frozenInfo.amount);
        }
    }

	/// @dev Uniform accuracy
    /// @param inputToken Initial token
    /// @param inputTokenAmount Amount of token
    /// @param outputToken Converted token
    /// @return stability Amount of outputToken
    function getDecimalConversion(address inputToken, 
    	                          uint256 inputTokenAmount, 
    	                          address outputToken) public view returns(uint256) {
    	uint256 inputTokenDec = 18;
    	uint256 outputTokenDec = 18;
    	if (inputToken != address(0x0)) {
    		inputTokenDec = ERC20(inputToken).decimals();
    	}
    	if (outputToken != address(0x0)) {
    		outputTokenDec = ERC20(outputToken).decimals();
    	}
    	return inputTokenAmount.mul(10**outputTokenDec).div(10**inputTokenDec);
    }

    //---------governance----------

    /// @dev Set contract status
    /// @param num 0: pause, 1: active, 2: redemption only
    function setFlag(uint8 num) public onlyGovernance {
        _flag = num;
    }

    /// @dev Set mortgage pool address
    function setMortgagePool(address add) public onlyGovernance {
    	_mortgagePool = add;
    }

    function setPTokenFactory(address add) public onlyGovernance {
        pTokenFactory = IPTokenFactory(add);
    }

    function setLPStakingMiningPool(address add) public onlyGovernance {
        lpStakingMiningPool = ILPStakingMiningPool(add);
    }

    /// @dev Set the latest redemption time
    function setLatestTime() public onlyGovernance {
        _latestTime = now.add(_waitCycle);
    }
    function setLatestTime(uint256 num) public onlyGovernance {
        _latestTime = num;
    }

    /// @dev Set the rate
    function setFeeRate(uint256 num) public onlyGovernance {
        _feeRate = num;
    }

    /// @dev Set redemption cycle
    function setRedemptionCycle(uint256 num) public onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _redemptionCycle = num * 1 days;
    }

    /// @dev Set redemption duration
    function setWaitCycle(uint256 num) public onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        _waitCycle = num * 1 days;
    }

    /// @dev Set the underlying asset and ptoken mapping and
    /// @param uToken underlying asset address
    /// @param pToken ptoken address
    function setInfo(address uToken, 
                     address pToken) public onlyGovernance {
        _pTokenAddress = pToken;
        _underlyingTokenAddress = uToken;
    }

    function setETHIns(bool isETHIns) public onlyGovernance {
        _ethIns = isETHIns;
    }

    //---------transaction---------

    /// @dev Set governance address
    function setGovernance() public {
        _governance = pTokenFactory.getGovernance();
    }

    /// @dev Exchange: ptoken exchanges the underlying asset
    /// @param amount amount of ptoken
    function exchangePTokenToUnderlying(uint256 amount) public whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Calculate the fee
    	uint256 fee = amount.mul(_feeRate).div(1000);

        // Transfer to the ptoken
    	ERC20(_pTokenAddress).safeTransferFrom(address(msg.sender), address(this), amount);

        // Calculate the amount of transferred underlying asset
        uint256 uTokenAmount = getDecimalConversion(_pTokenAddress, amount.sub(fee), _underlyingTokenAddress);
        require(uTokenAmount > 0, "Log:InsurancePool:!uTokenAmount");

        // Transfer out underlying asset
    	if (_ethIns) {
            TransferHelper.safeTransferETH(address(msg.sender), uTokenAmount);
    	} else {
            ERC20(_underlyingTokenAddress).safeTransfer(address(msg.sender), uTokenAmount);
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
    	uint256 fee = amount.mul(_feeRate).div(1000);

        // Transfer to the underlying asset
    	if (_ethIns) {
            // The underlying asset is ETH
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
    	} else {
            // The underlying asset is ERC20
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            ERC20(_underlyingTokenAddress).safeTransferFrom(address(msg.sender), address(this), amount);
    	}

        // Calculate the amount of transferred ptokens
        uint256 pTokenAmount = getDecimalConversion(_underlyingTokenAddress, amount.sub(fee), _pTokenAddress);
        require(pTokenAmount > 0, "Log:InsurancePool:!pTokenAmount");

        // Transfer out ptoken
        uint256 pTokenBalance = ERC20(_pTokenAddress).balanceOf(address(this));
        if (pTokenBalance < pTokenAmount) {
            // Insufficient ptoken balance,
            uint256 subNum = pTokenAmount.sub(pTokenBalance);
            IParasset(_pTokenAddress).issuance(subNum, address(this));
            _insNegative = _insNegative.add(subNum);
        }
    	ERC20(_pTokenAddress).safeTransfer(address(msg.sender), pTokenAmount);
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
    	if (now > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}

        // ptoken balance 
    	uint256 pTokenBalance = ERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_ethIns) {
            // The amount of ETH involved in the calculation does not include the transfer in this time
            require(msg.value == amount, "Log:InsurancePool:!msg.value");
            tokenBalance = address(this).balance.sub(amount);
    	} else {
            require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
            // Underlying asset conversion 18 decimals
            tokenBalance = getDecimalConversion(_underlyingTokenAddress, ERC20(_underlyingTokenAddress).balanceOf(address(this)), _pTokenAddress);
    	}

        // Calculate LP
    	uint256 insAmount = 0;
    	uint256 insTotal = totalSupply;
        uint256 allBalance = tokenBalance.add(pTokenBalance);
    	if (insTotal != 0) {
            // Insurance pool assets must be greater than 0
            require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
            uint256 allValue = allBalance.sub(_insNegative);
    		insAmount = getDecimalConversion(_underlyingTokenAddress, amount, _pTokenAddress).mul(insTotal).div(allValue);
    	} else {
            // The initial net value is 1
            insAmount = getDecimalConversion(_underlyingTokenAddress, amount, _pTokenAddress);
        }

    	// Transfer to the underlying asset(ERC20)
    	if (!_ethIns) {
    		require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
    		ERC20(_underlyingTokenAddress).safeTransferFrom(address(msg.sender), address(this), amount);
    	}

    	// Additional LP issuance
    	issuance(insAmount, address(msg.sender));

    	// Freeze insurance LP
    	frozenInfo.amount = frozenInfo.amount.add(insAmount);
    	frozenInfo.time = _latestTime.add(_waitCycle);
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
    	require(now >= tokenTime.sub(_waitCycle) && now <= tokenTime.sub(_waitCycle).add(_redemptionCycle), "Log:InsurancePool:!time");

        // Thaw LP
    	Frozen storage frozenInfo = frozenIns[address(msg.sender)];
    	if (now > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}
    	
        // ptoken balance
    	uint256 pTokenBalance = ERC20(_pTokenAddress).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (_ethIns) {
            tokenBalance = address(this).balance;
    	} else {
    		tokenBalance = getDecimalConversion(_underlyingTokenAddress, ERC20(_underlyingTokenAddress).balanceOf(address(this)), _pTokenAddress);
    	}

        // Insurance pool assets must be greater than 0
        uint256 allBalance = tokenBalance.add(pTokenBalance);
        require(allBalance > _insNegative, "Log:InsurancePool:allBalanceNotEnough");
        // Calculated amount of assets
    	uint256 allValue = allBalance.sub(_insNegative);
    	uint256 insTotal = totalSupply;
    	uint256 underlyingAmount = amount.mul(allValue).div(insTotal);

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
                ERC20(_pTokenAddress).safeTransfer(address(msg.sender), 
                                           underlyingAmount.sub(tokenBalance));
            }
    	} else {
            // ERC20
            if (tokenBalance >= underlyingAmount) {
                ERC20(_underlyingTokenAddress).safeTransfer(address(msg.sender), getDecimalConversion(_pTokenAddress, underlyingAmount, _underlyingTokenAddress));
            } else {
                ERC20(_underlyingTokenAddress).safeTransfer(address(msg.sender), getDecimalConversion(_pTokenAddress, tokenBalance, _underlyingTokenAddress));
                ERC20(_pTokenAddress).safeTransfer(address(msg.sender), underlyingAmount.sub(tokenBalance));
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
            uint256 subAmount = amount.sub(pTokenBalance);
    		_insNegative = _insNegative.add(subAmount);
            emit Negative(subAmount, _insNegative);
    	}
    }

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
    			_insNegative = _insNegative.sub(pTokenBalance);
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
    	if (now > time) {
    		uint256 subTime = now.sub(time).div(_waitCycle);
    		_latestTime = time.add(_waitCycle.mul(uint256(1).add(subTime)));
    	}
    }

    /// @dev Destroy LP
    /// @param amount quantity destroyed
    /// @param account destroy address
    function destroy(uint256 amount, 
                     address account) private {
        require(balances[account] >= amount, "Log:InsurancePool:!destroy");
        balances[account] = balances[account].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Destroy(amount, account);
    }

    /// @dev Additional LP issuance
    /// @param amount additional issuance quantity
    /// @param account additional issuance address
    function issuance(uint256 amount, 
                      address account) private {
        balances[account] = balances[account].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Issuance(amount, account);
    }

    function transfer(address to, uint256 value) public returns (bool) 
    {
        // // Update redemption time
        // updateLatestTime();

        // // Thaw LP
        // Frozen storage frozenInfo = frozenIns[address(msg.sender)];
        // if (now > frozenInfo.time) {
        //     frozenInfo.amount = 0;
        // }
        _transfer(msg.sender, to, value);

        // // Judgment to freeze LP
        // if (to != address(lpStakingMiningPool)) {
        //     require(getAllLP(address(msg.sender)) >= frozenInfo.amount, "Log:InsurancePool:frozen");
        // }
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) 
    {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) 
    {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function addETH() public payable {}

    function addToken(address tokenAddress, uint256 amount) public {
        ERC20(tokenAddress).safeTransferFrom(address(msg.sender), address(this), amount);
    }

}