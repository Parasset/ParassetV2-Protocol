// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPTokenFactory {
    /// @dev View governance address
    /// @return governance address
    function getGovernance() external view returns(address);

    /// @dev View ptoken operation permissions
    /// @param contractAddress contract address
    /// @return bool
    function getPTokenOperator(address contractAddress) external view returns(bool);

    /// @dev View ptoken operation permissions
    /// @param pToken ptoken verification
    /// @return bool
    function getPTokenAuthenticity(address pToken) external view returns(bool);
    function getPTokenAddress(uint256 index) external view returns(address);
}