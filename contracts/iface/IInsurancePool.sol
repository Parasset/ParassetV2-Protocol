// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IInsurancePool {
    
    /// @dev Destroy ptoken, update negative ledger
    /// @param amount quantity destroyed
    function destroyPToken(uint256 amount) external;

    /// @dev Clear negative books
    function eliminate() external;
}