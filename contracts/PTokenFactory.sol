// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./PToken.sol";
import "./ParassetBase.sol";
import "./iface/IPTokenFactory.sol";

contract PTokenFactory is ParassetBase, IPTokenFactory {

    // Governance contract
    address public _owner;
	// contract address => bool, ptoken operation permissions
	mapping(address=>bool) _allowAddress;
	// ptoken address => bool, ptoken verification
	mapping(address=>bool) _pTokenMapping;
    // ptoken address list
    address[] public _pTokenList;

    event createLog(address pTokenAddress);
    event pTokenOperator(address contractAddress, bool allow);

    //---------view---------

    /// @dev Concatenated string
    /// @param _a previous string
    /// @param _b after the string
    /// @return full string
    function strConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint s = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[s++] = _ba[i];
        } 
        for (uint i = 0; i < _bb.length; i++) {
            bret[s++] = _bb[i];
        } 
        return string(ret);
    }

    /// @dev View governance address
    /// @return governance address for PToken
    function getGovernance() external override view returns(address) {
        return _owner;
    }

    /// @dev View ptoken operation permissions
    /// @param contractAddress contract address
    /// @return bool
    function getPTokenOperator(address contractAddress) external override view returns(bool) {
    	return _allowAddress[contractAddress];
    }

    /// @dev View ptoken operation permissions
    /// @param pToken ptoken verification
    /// @return bool
    function getPTokenAuthenticity(address pToken) external override view returns(bool) {
    	return _pTokenMapping[pToken];
    }

    /// @dev Query ptoken address through index
    /// @param index array subscript
    /// @return pToken address
    function getPTokenAddress(uint256 index) external override view returns(address) {
        return _pTokenList[index];
    }

    //---------governance----------

    /// @dev Set owner address
    /// @param add new owner address
    function setOwner(address add) external onlyGovernance {
    	_owner = add;
    }

    /// @dev Set governance address
    /// @param contractAddress contract address
    /// @param allow bool
    function setPTokenOperator(address contractAddress, 
                               bool allow) external onlyGovernance {
        _allowAddress[contractAddress] = allow;
        emit pTokenOperator(contractAddress, allow);
    }

    /// @dev Add data to the ptoken array
    /// @param add pToken address
    function addPTokenList(address add) external onlyGovernance {
        _pTokenList.push(add);
    }

    /// @dev Create PToken
    /// @param name token name
    function createPtoken(string memory name) external onlyGovernance {
    	PToken pToken = new PToken(strConcat("PToken_", name), strConcat("P", name));
    	_pTokenMapping[address(pToken)] = true;
        _pTokenList.push(address(pToken));
    	emit createLog(address(pToken));
    }
}