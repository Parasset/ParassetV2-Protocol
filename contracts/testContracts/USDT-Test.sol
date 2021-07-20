// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../ParassetERC20.sol";

contract USDT is ParassetERC20 {
    constructor() {
        _name = "USDT";
        _symbol = "USDT";
        _totalSupply = 100000000 ether;
        _balances[msg.sender] = _totalSupply;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return 6;
    }
}