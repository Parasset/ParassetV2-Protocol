// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../ParassetERC20.sol";

contract NEST is ParassetERC20 {
    constructor() {
        _name = "NEST";
        _symbol = "NEST";
        _totalSupply = 10000000000 ether;
        _balances[msg.sender] = _totalSupply;
    }
}