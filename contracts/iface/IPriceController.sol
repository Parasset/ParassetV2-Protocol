// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPriceController {
    function getPriceForPToken(address token, address uToken, address payback) external payable returns (uint256 tokenPrice, uint256 pTokenPrice);
}