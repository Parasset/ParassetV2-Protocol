// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./iface/INestPriceFacade.sol";
import "./iface/IPriceController.sol";
import "./iface/INTokenController.sol";
import "./iface/IERC20.sol";

contract PriceController is IPriceController {

	// Nest price contract
    INestPriceFacade _nestPriceFacade;
    // NTokenController
    INTokenController _nTokenController;

    /// @dev Initialization method
    /// @param nestPriceFacade Nest price contract
    /// @param nTokenController NTokenController
	constructor (address nestPriceFacade, address nTokenController) {
		_nestPriceFacade = INestPriceFacade(nestPriceFacade);
        _nTokenController = INTokenController(nTokenController);
    }

    /// @dev Is it a token-NToken price pair
    /// @param tokenOne token address(USDT,HBTC...)
    /// @param tokenTwo NToken address(NEST,NHBTC...)
    function checkNToken(address tokenOne, address tokenTwo) public view returns(bool) {
        if (_nTokenController.getNTokenAddress(tokenOne) == tokenTwo) {
            return true;
        }
        return false;
    }

    /// @dev Uniform accuracy
    /// @param inputToken Initial token
    /// @param inputTokenAmount Amount of token
    /// @param outputToken Converted token
    /// @return stability Amount of outputToken
    function getDecimalConversion(
        address inputToken, 
        uint256 inputTokenAmount, 
        address outputToken
    ) public view returns(uint256) {
    	uint256 inputTokenDec = 18;
    	uint256 outputTokenDec = 18;
    	if (inputToken != address(0x0)) {
    		inputTokenDec = IERC20(inputToken).decimals();
    	}
    	if (outputToken != address(0x0)) {
    		outputTokenDec = IERC20(outputToken).decimals();
    	}
    	return inputTokenAmount * (10**outputTokenDec) / (10**inputTokenDec);
    }

    /// @dev Get price
    /// @param token mortgage asset address
    /// @param uToken underlying asset address
    /// @param payback return address of excess fee
    /// @return tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @return pTokenPrice PToken price(1 ETH = ? pToken)
    function getPriceForPToken(
        address token, 
        address uToken,
        address payback
    ) public payable override returns (
        uint256 tokenPrice, 
        uint256 pTokenPrice
    ) {
        if (token == address(0x0)) {
            // The mortgage asset is ETH???get ERC20-ETH price
            (,,uint256 avg,) = _nestPriceFacade.triggeredPriceInfo{value:msg.value}(uToken, payback);
            require(avg > 0, "Log:PriceController:!avg1");
            return (1 ether, getDecimalConversion(uToken, avg, address(0x0)));
        } else if (uToken == address(0x0)) {
            // The underlying asset is ETH???get ERC20-ETH price
            (,,uint256 avg,) = _nestPriceFacade.triggeredPriceInfo{value:msg.value}(token, payback);
            require(avg > 0, "Log:PriceController:!avg2");
            return (avg, 1 ether);
        } else {
            // Get ERC20-ERC20 price
            if (checkNToken(token, uToken)) {
                (,,uint256 avg1,,,,uint256 avg2,) = _nestPriceFacade.triggeredPriceInfo2{value:msg.value}(token, payback);
                require(avg1 > 0 && avg2 > 0, "Log:PriceController:!avg3");
                return (avg1, getDecimalConversion(uToken, avg2, address(0x0)));
            } else if (checkNToken(uToken, token)) {
                (,,uint256 avg1,,,,uint256 avg2,) = _nestPriceFacade.triggeredPriceInfo2{value:msg.value}(uToken, payback);
                require(avg1 > 0 && avg2 > 0, "Log:PriceController:!avg4");
                return (avg2, getDecimalConversion(uToken, avg1, address(0x0)));
            } else {
                uint256 priceValue = uint256(msg.value) / 2;
                (,,uint256 avg1,) = _nestPriceFacade.triggeredPriceInfo{value:priceValue}(token, payback);
                (,,uint256 avg2,) = _nestPriceFacade.triggeredPriceInfo{value:priceValue}(uToken, payback);
                require(avg1 > 0 && avg2 > 0, "Log:PriceController:!avg5");
                return (avg1, getDecimalConversion(uToken, avg2, address(0x0)));
            }
        }
    }
}