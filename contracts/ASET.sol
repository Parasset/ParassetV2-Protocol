// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ParassetERC20.sol";

contract ASET is ParassetERC20 {
    constructor() {
        _name = "ASET";
        _symbol = "ASET";
        _totalSupply = 100000000 ether;
        _balances[msg.sender] = _totalSupply;
    }
}