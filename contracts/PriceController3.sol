// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./iface/INestPriceFacadeForNest4.sol";
import "./iface/INestPriceFacade.sol";
import "./iface/IPriceController.sol";
import "./iface/IERC20.sol";

contract PriceController3 is IPriceController {
    // Nest price contract
    INestPriceFacadeForNest4 immutable _nestBatchPlatform;
    INestPriceFacade immutable _nestPriceFacade;
    // usdt address
    address constant USDT_ADDRESS =
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    // nest address
    address constant NEST_ADDRESS =
        address(0x04abEdA201850aC0124161F037Efd70c74ddC74C);
    // HBTC address
    address constant HBTC_ADDRESS =
        address(0x0316EB71485b0Ab14103307bf65a021042c6d380);
    // nest4 base usdt amount
    uint256 constant BASE_USDT_AMOUNT = 2000 ether;
    // nest4 channel id
    uint256 constant CHANNELID = 0;
    // asset token address => price index
    mapping(address => uint256) addressToPriceIndex;
    // price fee
    uint256 public nest3Fee = 0.001 ether;
    // owner address
    address public owner;

    /// @dev Initialization method
    /// @param nestBatchPlatform Nest price contract
    /// @param nestPriceFacade Nest price contract
    constructor(address nestBatchPlatform, address nestPriceFacade) {
        _nestBatchPlatform = INestPriceFacadeForNest4(nestBatchPlatform);
        _nestPriceFacade = INestPriceFacade(nestPriceFacade);

        addressToPriceIndex[HBTC_ADDRESS] = 0;
        owner = msg.sender;
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
    ) public view returns (uint256) {
        uint256 inputTokenDec = 18;
        uint256 outputTokenDec = 18;
        if (inputToken != address(0x0)) {
            inputTokenDec = IERC20(inputToken).decimals();
        }
        if (outputToken != address(0x0)) {
            outputTokenDec = IERC20(outputToken).decimals();
        }
        return (inputTokenAmount * (10**outputTokenDec)) / (10**inputTokenDec);
    }

    function checkAddressToPriceIndex(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return addressToPriceIndex[tokenAddress];
    }

    function setNest3Fee(uint256 num) external {
        require(msg.sender == owner, "Log:PriceController:!owner");
        nest3Fee = num;
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
    )
        public
        payable
        override
        returns (uint256 tokenPrice, uint256 pTokenPrice)
    {
        require(uToken == HBTC_ADDRESS, "Log:PriceController:!uToken");
        if (token == address(0x0)) {
            // The mortgage asset is ETH，get USDT-ETH price
            (, , uint256 avg, ) = _nestPriceFacade.triggeredPriceInfo{
                value: nest3Fee
            }(USDT_ADDRESS, payback);
            require(avg > 0, "Log:PriceController:!avg nest3");

            uint256[] memory pricesIndex = new uint256[](1);
            pricesIndex[0] = addressToPriceIndex[token];
            // get HBTC-USDT price
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{
                value: msg.value - nest3Fee
            }(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0, "Log:PriceController:!avg nest4");
            uint256 priceETH = (getDecimalConversion(
                USDT_ADDRESS,
                avg,
                address(0x0)
            ) * prices[2]) / BASE_USDT_AMOUNT;
            return (1 ether, priceETH);
        } else if (token == NEST_ADDRESS) {
            // The mortgage asset is nest，get USDT-NEST price
            (, , uint256 avg1, , , , uint256 avg2, ) = _nestPriceFacade
                .triggeredPriceInfo2{value: nest3Fee}(USDT_ADDRESS, payback);
            require(avg1 > 0 && avg2 > 0, "Log:PriceController:!avg nest3");

            uint256[] memory pricesIndex = new uint256[](1);
            pricesIndex[0] = addressToPriceIndex[token];
            // get HBTC-USDT price
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{
                value: msg.value - nest3Fee
            }(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0, "Log:PriceController:!avg nest4");
            uint256 priceETH = (getDecimalConversion(
                USDT_ADDRESS,
                avg1,
                address(0x0)
            ) * prices[2]) / BASE_USDT_AMOUNT;
            return (avg2, priceETH);
        } else {
            revert("Log:PriceController:no token");
        }
    }
}
