// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface INestPriceFacadeForNest4 {
    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 4 为第i个价格所在区块, i * 4 + 1 为第i个价格, i * 4 + 2 为第i个平均价格, i * 4 + 3 为第i个波动率
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices);
}