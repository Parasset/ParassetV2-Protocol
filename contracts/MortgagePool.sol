// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./iface/IParasset.sol";
import "./iface/IInsurancePool.sol";
import "./iface/IPTokenFactory.sol";
import "./iface/IPriceController.sol";
import "./lib/SafeMath.sol";
import './lib/TransferHelper.sol';
import './lib/SafeERC20.sol';
import "./lib/ReentrancyGuard.sol";

contract MortgagePool is ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

    // governance address
	address public _governance;
    Config config;
    // mortgage asset address => mortgage config
    mapping(address => MortgageInfo) mortageConfig;
    // mortgage asset address => ledger info
    mapping(address => MortageLeader) ledgerList;
    // priceController contract
    IPriceController quary;
    // insurance pool contract
    IInsurancePool insurancePool;
    // pToken creation factory contract
    IPTokenFactory pTokenFactory;

    struct MortgageInfo {
        // allow mortgage
        bool mortgageAllow;
        // six digits, 0.75=75000
        uint88 maxRate;
        // six digits, 1.3=130000
        uint80 k;
        // six digits, 0.02=2000
        uint80 r0;
    }
    struct MortageLeader {
        // debt data
        mapping(address => PersonalLedger) ledger;
        // users who have created debt positions(address)
        address[] ledgerArray;
    }
    struct PersonalLedger {
        // amount of mortgaged assets
        uint256 mortgageAssets;
        // amount of debt(Ptoken,Stability fee not included)      
        uint256 parassetAssets;
        // the block height of the last operation       
        uint160 blockHeight;
        // mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)           
        uint88 rate;
        // is it created
        bool created;
    }
    struct Config {
        // pToken address
        address pTokenAdd;
        // amount of blocks produced in a year            
        uint96 oneYearBlock;
        // underlyingToken address           
        address underlyingTokenAdd;
        // = 0: pause
        // = 1: active
        // = 2: out only  
        uint96 flag;                    
    }

    event FeeValue(uint256 value);
    event LedgerLog(address mToken, uint256 mTokenAmount, uint256 pTokenAmount, uint256 tokenPrice, uint256 pTokenPrice, uint88 rate);

    /// @dev Initialization method
    /// @param factoryAddress PToken creation factory contract
	constructor (address factoryAddress) public {
        pTokenFactory = IPTokenFactory(factoryAddress);
        _governance = pTokenFactory.getGovernance();
        config.flag = 0;
        config.oneYearBlock = 2400000;
    }

    //---------modifier---------

    modifier onlyGovernance() {
        require(msg.sender == _governance, "Log:MortgagePool:!gov");
        _;
    }

    modifier whenActive() {
        require(config.flag == 1, "Log:MortgagePool:!active");
        _;
    }

    modifier outOnly() {
        require(config.flag != 0, "Log:MortgagePool:!0");
        _;
    }

    //---------view---------

    /// @dev Calculate the stability fee
    /// @param parassetAssets Amount of debt(Ptoken,Stability fee not included)
    /// @param blockHeight The block height of the last operation
    /// @param rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @param nowRate Current mortgage rate (not including stability fee)
    /// @return fee
    function getFee(uint256 parassetAssets, 
    	            uint160 blockHeight,
    	            uint256 rate,
                    uint256 nowRate,
                    uint80 r0Value) 
    public view returns(uint256) {
        uint256 topOne = parassetAssets.mul(uint256(r0Value)).mul(block.number.sub(uint256(blockHeight)));
        uint256 ratePlus = rate.add(nowRate);
        uint256 topTwo = parassetAssets.mul(uint256(r0Value)).mul(block.number.sub(uint256(blockHeight))).mul(uint256(3).mul(ratePlus));
    	uint256 bottom = uint256(config.oneYearBlock).mul(100000);
    	return topOne.div(bottom).add(topTwo.div(bottom.mul(100000).mul(2)));
    }

    /// @dev Calculate the mortgage rate
    /// @param mortgageAssets Amount of mortgaged assets
    /// @param parassetAssets Amount of debt
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param pTokenPrice PToken price(1 ETH = ? pToken)
    /// @return mortgage rate
    function getMortgageRate(uint256 mortgageAssets,
    	                     uint256 parassetAssets, 
    	                     uint256 tokenPrice, 
    	                     uint256 pTokenPrice) 
    public pure returns(uint88) {
        if (mortgageAssets == 0 || pTokenPrice == 0) {
            return 0;
        }
    	return uint88(parassetAssets.mul(tokenPrice).mul(100000).div(pTokenPrice.mul(mortgageAssets)));
    }

    /// @dev Get real-time data of the current debt warehouse
    /// @param mortgageToken Mortgage asset addresss
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param uTokenPrice Underlying asset price(1 ETH = ? Underlying asset)
    /// @param maxRateNum Maximum mortgage rate
    /// @param owner Debt owner
    /// @return fee Stability fee
    /// @return mortgageRate Real-time mortgage rate(Including stability fee)
    /// @return maxSubM The maximum amount of mortgage assets can be reduced
    /// @return maxAddP Maximum number of coins that can be added
    function getInfoRealTime(address mortgageToken,
                             uint256 tokenPrice, 
                             uint256 uTokenPrice,
                             uint88 maxRateNum,
                             uint256 owner) 
    public view returns(uint256 fee, 
                        uint256 mortgageRate, 
                        uint256 maxSubM, 
                        uint256 maxAddP) {
        address mToken = mortgageToken;
        PersonalLedger memory pLedger = ledgerList[mToken].ledger[address(owner)];
        if (pLedger.mortgageAssets == 0 && pLedger.parassetAssets == 0) {
            return (0,0,0,0);
        }
        uint256 pTokenPrice = getDecimalConversion(config.underlyingTokenAdd, uTokenPrice, config.pTokenAdd);
        uint256 tokenPriceAmount = tokenPrice;
        fee = getFee(pLedger.parassetAssets, pLedger.blockHeight, pLedger.rate, getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPriceAmount, pTokenPrice), mortageConfig[mToken].r0);
        mortgageRate = getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets.add(fee), tokenPriceAmount, pTokenPrice);
        uint256 mRateNum = maxRateNum;
        if (mortgageRate >= mRateNum) {
            maxSubM = 0;
            maxAddP = 0;
        } else {
            maxSubM = pLedger.mortgageAssets.sub(pLedger.parassetAssets.mul(tokenPriceAmount).mul(100000).div(mRateNum.mul(pTokenPrice)));
            maxAddP = pLedger.mortgageAssets.mul(pTokenPrice).mul(mRateNum).div(uint256(100000).mul(tokenPriceAmount)).sub(pLedger.parassetAssets);
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

    /// @dev View debt warehouse data
    /// @param mortgageToken mortgage asset address
    /// @param owner debt owner
    /// @return mortgageAssets amount of mortgaged assets
    /// @return parassetAssets amount of debt(Ptoken,Stability fee not included)
    /// @return blockHeight the block height of the last operation
    /// @return rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @return created is it created
    function getLedger(address mortgageToken,
                       address owner) 
    public view returns(uint256 mortgageAssets, 
    		            uint256 parassetAssets, 
    		            uint160 blockHeight,
                        uint88 rate,
                        bool created) {
    	PersonalLedger memory pLedger = ledgerList[mortgageToken].ledger[address(owner)];
    	return (pLedger.mortgageAssets, pLedger.parassetAssets, pLedger.blockHeight, pLedger.rate, pLedger.created);
    }

    /// @dev View the insurance pool address
    /// @return insurance pool address
    function getInsurancePool() external view returns(address) {
        return address(insurancePool);
    }

    /// @dev View the market base interest rate
    /// @return market base interest rate
    function getR0(address mortgageToken) external view returns(uint80) {
    	return mortageConfig[mortgageToken].r0;
    }

    /// @dev View the amount of blocks produced in a year
    /// @return amount of blocks produced in a year
    function getOneYear() external view returns(uint96) {
    	return config.oneYearBlock;
    }

    /// @dev View the maximum mortgage rate
    /// @param mortgageToken Mortgage asset address
    /// @return maximum mortgage rate
    function getMaxRate(address mortgageToken) external view returns(uint88) {
    	return mortageConfig[mortgageToken].maxRate;
    }

    /// @dev View the k value
    /// @param mortgageToken Mortgage asset address
    /// @return k value
    function getK(address mortgageToken) external view returns(uint256) {
        return mortageConfig[mortgageToken].k;
    }

    /// @dev View the priceController contract address
    /// @return priceController contract address
    function getPriceController() external view returns(address) {
        return address(quary);
    }

    /// @dev View the debt array length
    /// @param mortgageToken mortgage asset address
    /// @return debt array length
    function getLedgerArrayNum(address mortgageToken) external view returns(uint256) {
        return ledgerList[mortgageToken].ledgerArray.length;
    }

    /// @dev View the debt owner
    /// @param mortgageToken mortgage asset address
    /// @param index array subscript
    /// @return debt owner
    function getLedgerAddress(address mortgageToken, 
                              uint256 index) external view returns(address) {
        return ledgerList[mortgageToken].ledgerArray[index];
    }

    /// @dev View the pToken address
    /// @return pToken address
    function getPtokenAddress() external view returns(address) {
        return config.pTokenAdd;
    }

    /// @dev View the underlyingToken address
    /// @return underlyingToken address
    function getUnderlyingToken() external view returns(address) {
        return config.underlyingTokenAdd;
    }

    /// @dev View the flag num
    /// @return flag num
    function getFlag() external view returns(uint96) {
        return config.flag;
    }

    //---------governance----------

    function setConfig(address pTokenAdd, uint96 oneYear, address underlyingTokenAdd, uint96 flag) public onlyGovernance {
        config.pTokenAdd = pTokenAdd;
        config.oneYearBlock = oneYear;
        config.underlyingTokenAdd = underlyingTokenAdd;
        config.flag = flag;
    }

    /// @dev Set contract status
    /// @param num 0: pause, 1: active, 2: out only
    function setFlag(uint96 num) public onlyGovernance {
        config.flag = num;
    }

    /// @dev Allow asset mortgage to generate ptoken
    /// @param mortgageToken mortgage asset address
    /// @param allow allow mortgage
    function setMortgageAllow(address mortgageToken, 
    	                      bool allow) public onlyGovernance {
    	mortageConfig[mortgageToken].mortgageAllow = allow;
    }

    /// @dev Set insurance pool contract
    /// @param add insurance pool contract
    function setInsurancePool(address add) public onlyGovernance {
        insurancePool = IInsurancePool(add);
    }

    /// @dev Set market base interest rate
    /// @param num market base interest rate(num = ? * 1 ether)
    function setR0(address mortgageToken, uint80 num) public onlyGovernance {
    	mortageConfig[mortgageToken].r0 = num;
    }

    /// @dev Set the amount of blocks produced in a year
    /// @param num amount of blocks produced in a year
    function setOneYear(uint96 num) public onlyGovernance {
    	config.oneYearBlock = num;
    }

    /// @dev Set K value
    /// @param mortgageToken mortgage asset address
    /// @param num K value
    function setK(address mortgageToken, 
                  uint80 num) public onlyGovernance {
        mortageConfig[mortgageToken].k = num;
    }

    /// @dev Set the maximum mortgage rate
    /// @param mortgageToken mortgage asset address
    /// @param num maximum mortgage rate(num = ? * 1000)
    function setMaxRate(address mortgageToken, 
                        uint88 num) public onlyGovernance {
        mortageConfig[mortgageToken].maxRate = num;
    }

    /// @dev Set priceController contract address
    /// @param add priceController contract address
    function setPriceController(address add) public onlyGovernance {
        quary = IPriceController(add);
    }

    /// @dev Set the underlying asset and ptoken mapping and
    /// @param uToken underlying asset address
    /// @param pToken ptoken address
    function setInfo(address uToken, 
                     address pToken) public onlyGovernance {
        config.pTokenAdd = pToken;
        config.underlyingTokenAdd = uToken;
    }

    //---------transaction---------

    /// @dev Set governance address
    function setGovernance() public {
        _governance = pTokenFactory.getGovernance();
    }

    /// @dev Mortgage asset casting ptoken
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    /// @param rate custom mortgage rate
    function coin(address mortgageToken,
                  uint256 amount, 
                  uint88 rate) public payable whenActive nonReentrant {
        MortgageInfo memory morInfo = mortageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        require(rate > 0 && uint256(rate).mul(1000) <= morInfo.maxRate, "Log:MortgagePool:rate!=0");
        require(amount > 0, "Log:MortgagePool:amount!=0");
    	PersonalLedger storage pLedger = ledgerList[mortgageToken].ledger[address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;

    	// Get the price and transfer to the mortgage token
        uint256 tokenPrice;
        uint256 pTokenPrice;
        if (mortgageToken != address(0x0)) {
            ERC20(mortgageToken).safeTransferFrom(address(msg.sender), address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, uint256(msg.value).sub(amount));
        }

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Additional ptoken issuance
        uint256 pTokenAmount = amount.mul(pTokenPrice).mul(rate).div(tokenPrice.mul(100));
        IParasset(config.pTokenAdd).issuance(pTokenAmount, address(msg.sender));

        // Update debt information
        pLedger.mortgageAssets = mortgageAssets.add(amount);
        pLedger.parassetAssets = parassetAssets.add(pTokenAmount);
        pLedger.blockHeight = uint160(block.number);
        pLedger.rate = getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);
        // Tag created
        if (pLedger.created == false) {
            ledgerList[mortgageToken].ledgerArray.push(address(msg.sender));
            pLedger.created = true;
        }
    }

    /// @dev Increase mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    function supplement(address mortgageToken, 
                        uint256 amount) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = mortageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        require(amount > 0, "Log:MortgagePool:!amount");
    	PersonalLedger storage pLedger = ledgerList[mortgageToken].ledger[address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(pLedger.created, "Log:MortgagePool:!created");

    	// Get the price and transfer to the mortgage token
        uint256 tokenPrice;
        uint256 pTokenPrice;
        if (mortgageToken != address(0x0)) {
            ERC20(mortgageToken).safeTransferFrom(address(msg.sender), address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, uint256(msg.value).sub(amount));
        }

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
    	pLedger.mortgageAssets = mortgageAssets.add(amount);
    	pLedger.blockHeight = uint160(block.number);
        pLedger.rate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);
    }

    /// @dev Reduce mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    function decrease(address mortgageToken, 
                      uint256 amount) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = mortageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
    	PersonalLedger storage pLedger = ledgerList[mortgageToken].ledger[address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= mortgageAssets, "Log:MortgagePool:!amount");
        require(pLedger.created, "Log:MortgagePool:!created");

    	// Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
    	pLedger.mortgageAssets = mortgageAssets.sub(amount);
    	pLedger.blockHeight = uint160(block.number);
        pLedger.rate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);

        // The debt warehouse mortgage rate cannot be greater than the maximum mortgage rate
    	require(pLedger.rate <= morInfo.maxRate, "Log:MortgagePool:!maxRate");

    	// Transfer out mortgage assets
    	if (mortgageToken != address(0x0)) {
    		ERC20(mortgageToken).safeTransfer(address(msg.sender), amount);
    	} else {
            TransferHelper.safeTransferETH(address(msg.sender), amount);
    	}
    }

    /// @dev Increase debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of debt
    function increaseCoinage(address mortgageToken,
                             uint256 amount) public payable whenActive nonReentrant {
        MortgageInfo memory morInfo = mortageConfig[mortgageToken];
        require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        require(amount > 0, "Log:MortgagePool:!amount");
        PersonalLedger storage pLedger = ledgerList[mortgageToken].ledger[address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(pLedger.created, "Log:MortgagePool:!created");

        // Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
        pLedger.parassetAssets = parassetAssets.add(amount);
        pLedger.blockHeight = uint160(block.number);
        pLedger.rate = getMortgageRate(mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);

        // The debt warehouse mortgage rate cannot be greater than the maximum mortgage rate
        require(pLedger.rate <= morInfo.maxRate, "Log:MortgagePool:!maxRate");

        // Additional ptoken issuance
        IParasset(config.pTokenAdd).issuance(amount, address(msg.sender));
    }

    /// @dev Reduce debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of debt
    function reducedCoinage(address mortgageToken,
                            uint256 amount) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = mortageConfig[mortgageToken];
        require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
        PersonalLedger storage pLedger = ledgerList[mortgageToken].ledger[address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= parassetAssets, "Log:MortgagePool:!amount");
        require(pLedger.created, "Log:MortgagePool:!created");

        // Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);

        // Calculate the stability fee
        transferFee(pLedger, tokenPrice, pTokenPrice, morInfo.r0);

        // Update debt information
        pLedger.parassetAssets = parassetAssets.sub(amount);
        pLedger.blockHeight = uint160(block.number);
        pLedger.rate = getMortgageRate(mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);

        // Destroy ptoken
        insurancePool.destroyPToken(amount);
    }

    /// @dev Liquidation of debt
    /// @param mortgageToken mortgage asset address
    /// @param account debt owner address
    /// @param amount amount of mortgaged assets
    function liquidation(address mortgageToken,
                         address account,
                         uint256 amount) public payable outOnly nonReentrant {
        MortgageInfo memory morInfo = mortageConfig[mortgageToken];
    	require(morInfo.mortgageAllow, "Log:MortgagePool:!mortgageAllow");
    	PersonalLedger storage pLedger = ledgerList[mortgageToken].ledger[address(account)];
        require(pLedger.created, "Log:MortgagePool:!created");
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= mortgageAssets, "Log:MortgagePool:!amount");

    	// Get the price
    	(uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, msg.value);
        
        // Judging the liquidation line
        checkLine(pLedger, tokenPrice, pTokenPrice, morInfo.k, morInfo.r0);

        // Calculate the amount of ptoken
        uint256 pTokenAmount = amount.mul(pTokenPrice).mul(90).div(tokenPrice.mul(100));
    	// Transfer to ptoken
    	ERC20(config.pTokenAdd).safeTransferFrom(address(msg.sender), address(insurancePool), pTokenAmount);

    	// Eliminate negative accounts
        insurancePool.eliminate();

        // Calculate the debt for destruction
        uint256 offset = parassetAssets.mul(amount).div(mortgageAssets);

        // Destroy ptoken
    	insurancePool.destroyPToken(offset);

    	// Update debt information
    	pLedger.mortgageAssets = mortgageAssets.sub(amount);
        pLedger.parassetAssets = parassetAssets.sub(offset);
        emit LedgerLog(mortgageToken, pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice, pLedger.rate);
        // MortgageAssets liquidation, mortgage rate and block number are not updated
        if (pLedger.mortgageAssets == 0) {
            pLedger.parassetAssets = 0;
            pLedger.blockHeight = 0;
            pLedger.rate = 0;
        }

    	// Transfer out mortgage asset
    	if (mortgageToken != address(0x0)) {
    		ERC20(mortgageToken).safeTransfer(address(msg.sender), amount);
    	} else {
            TransferHelper.safeTransferETH(address(msg.sender), amount);
    	}
    }

    /// @dev Check the liquidation line
    /// @param pLedger debt warehouse ledger
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param pTokenPrice PToken price(1 ETH = ? pToken)
    function checkLine(PersonalLedger memory pLedger, 
                       uint256 tokenPrice, 
                       uint256 pTokenPrice, 
                       uint80 kValue,
                       uint80 r0Value) public view {
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        // The current mortgage rate cannot exceed the liquidation line
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
        uint256 fee = 0;
        uint160 blockHeight = pLedger.blockHeight;
        if (parassetAssets > 0 && uint160(block.number) > blockHeight && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate, mortgageRate, r0Value);
        }
        require(parassetAssets.add(fee).mul(kValue).div(mortgageAssets.mul(100000)) < pTokenPrice.div(tokenPrice), "Log:MortgagePool:!liquidationLine");
    }

    function transferFee(PersonalLedger memory pLedger, uint256 tokenPrice, uint256 pTokenPrice, uint80 r0Value) private {
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        uint256 rate = pLedger.rate;
        uint160 blockHeight = pLedger.blockHeight;
        if (parassetAssets > 0 && uint160(block.number) > blockHeight && blockHeight != 0) {
            uint256 fee = getFee(parassetAssets, blockHeight, rate, getMortgageRate(mortgageAssets, parassetAssets, tokenPrice, pTokenPrice), r0Value);
            // The stability fee is transferred to the insurance pool
            ERC20(config.pTokenAdd).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // Eliminate negative accounts
            insurancePool.eliminate();
            emit FeeValue(fee);
        }
    }

    /// @dev Get price
    /// @param mortgageToken mortgage asset address
    /// @param priceValue price fee
    /// @return tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @return pTokenPrice PToken price(1 ETH = ? pToken)
    function getPriceForPToken(address mortgageToken,
                               uint256 priceValue) private returns (uint256 tokenPrice, 
                                                                    uint256 pTokenPrice) {
        (tokenPrice, pTokenPrice) = quary.getPriceForPToken{value:priceValue}(mortgageToken, config.underlyingTokenAdd, msg.sender);   
    }

}