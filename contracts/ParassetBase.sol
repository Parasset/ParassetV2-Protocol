// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./iface/IParassetGovernance.sol";

contract ParassetBase {

	/// @dev To support open-zeppelin/upgrades
    /// @param governance IParassetGovernance implementation contract address
    function initialize(address governance) virtual public {
        require(_governance == address(0), 'Log:ParassetBase!initialize');
        _governance = governance;
    }

    /// @dev IParassetGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IParassetGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IParassetGovernance(governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _governance = newGovernance;
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IParassetGovernance(_governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _;
    }
}