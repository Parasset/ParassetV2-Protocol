// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./iface/INestPriceFacadeForNest4.sol";
import "./iface/IPriceController.sol";
import "./iface/IERC20.sol";

contract PriceController is IPriceController {

    // Nest价格合约
    INestPriceFacadeForNest4 _nestBatchPlatform;
    // TODO:usdt address
    address constant USDT_ADDRESS = address(0x0);
    // TODO:usdt报价单位
    uint256 constant BASE_USDT_AMOUNT = 2000 ether;
    // TODO:报价轨道id
    uint256 constant CHANNELID = 0;
    // 资产地址对应的报价对编号
    mapping(address => uint256) addressToPriceIndex;

    /// @dev Initialization method
    /// @param nestBatchPlatform Nest price contract
	constructor (address nestBatchPlatform) {
		_nestBatchPlatform = INestPriceFacadeForNest4(nestBatchPlatform);
        // TODO
        addressToPriceIndex[address(0x8eF7Eec35b064af3b38790Cd0Afd3CF2FF5203A4)] = 0;
        addressToPriceIndex[address(0x0)] = 1;
        addressToPriceIndex[address(0x2Eb7850D7e14d3E359ce71B5eBbb03BbE732d6DD)] = 2;
    }

    function getAddressToPriceIndex(
        address tokenAddress
    ) public view returns(uint256) {
        return addressToPriceIndex[tokenAddress];
    }

    /// @dev Get price
    /// @param token mortgage asset address
    /// @param uToken underlying asset address
    /// @param payback return address of excess fee
    /// @return tokenPrice Mortgage asset price(2000U = ? token)
    /// @return pTokenPrice PToken price(2000U = ? pToken)
    function getPriceForPToken(
        address token, 
        address uToken,
        address payback
    ) public payable override returns (
        uint256 tokenPrice, 
        uint256 pTokenPrice
    ) {
        if(uToken == address(USDT_ADDRESS)) {
            uint256[] memory pricesIndex = new uint256[](1);
            pricesIndex[0] = addressToPriceIndex[token];
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{value:msg.value}(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0, "Log:PriceController:!avg");
            return(prices[2], BASE_USDT_AMOUNT);
        } else {
            uint256[] memory pricesIndex = new uint256[](2);
            pricesIndex[0] = addressToPriceIndex[token];
            pricesIndex[1] = addressToPriceIndex[uToken];
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{value:msg.value}(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0 && prices[6] > 0, "Log:PriceController:!avg");
            return(prices[2], prices[6]);
        }
    }
}