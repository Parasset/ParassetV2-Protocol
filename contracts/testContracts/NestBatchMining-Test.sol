// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '../lib/TransferHelper.sol';

contract NestBatchMining {

    mapping(uint256 => mapping(uint256 => uint256)) _avgPrice;
    uint256 fee = 0.001 ether; 

    constructor() public {
        _avgPrice[0][0] = 0.066 ether;
        _avgPrice[0][1] = 0.5 ether;
        _avgPrice[0][2] = 200000 ether;
    }

    function setAvg(uint256 index, uint256 value) external {
        _avgPrice[0][index] = value;
    }
    
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices){
        _pay(payback);
        uint n = pairIndices.length << 2;
        prices = new uint[](n);
        if (pairIndices.length == 1) {
            prices[0] = 0;
            prices[1] = 0;
            prices[2] = _avgPrice[channelId][pairIndices[0]];
            prices[3] = 0;
        } else {
            prices[0] = 0;
            prices[1] = 0;
            prices[2] = _avgPrice[channelId][pairIndices[0]];
            prices[3] = 0;
            prices[4] = 0;
            prices[5] = 0;
            prices[6] = _avgPrice[channelId][pairIndices[1]];
            prices[7] = 0;
        }
    }

    function triggeredPriceInfo(uint channelId, uint pairIndex) external view returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {
        return (0,0,_avgPrice[channelId][pairIndex],0);
    }

    function _pay(address paybackAddress) private {
        if (msg.value > fee) {
            TransferHelper.safeTransferETH(paybackAddress, msg.value - fee);
            TransferHelper.safeTransferETH(address(0x688f016CeDD62AD1d8dFA4aBcf3762ab29294489), fee);
        } else {
            require(msg.value == fee, "NestPriceFacade:!fee");
            TransferHelper.safeTransferETH(address(0x688f016CeDD62AD1d8dFA4aBcf3762ab29294489), msg.value);
        }
    }
}