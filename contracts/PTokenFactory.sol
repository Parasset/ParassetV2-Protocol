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

    event createLog(address pTokenAddress);
    event pTokenOperator(address contractAddress, bool allow);

    //---------view---------

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
    function getGovernance() override public view returns(address) {
        return _owner;
    }

    /// @dev View ptoken operation permissions
    /// @param contractAddress contract address
    /// @return bool
    function getPTokenOperator(address contractAddress) override public view returns(bool) {
    	return _allowAddress[contractAddress];
    }

    /// @dev View ptoken operation permissions
    /// @param pToken ptoken verification
    /// @return bool
    function getPTokenAuthenticity(address pToken) override public view returns(bool) {
    	return _pTokenMapping[pToken];
    }

    //---------governance----------

    /// @dev Set owner address
    /// @param add new owner address
    function setOwner(address add) public onlyGovernance {
    	_owner = add;
    }

    /// @dev Set governance address
    /// @param contractAddress contract address
    /// @param allow bool
    function setPTokenOperator(address contractAddress, 
                               bool allow) public onlyGovernance {
        _allowAddress[contractAddress] = allow;
        emit pTokenOperator(contractAddress, allow);
    }

    /// @dev Create PToken
    /// @param name token name
    function createPtoken(string memory name) public onlyGovernance {
    	PToken pToken = new PToken(strConcat("PToken_", name), strConcat("P", name));
    	_pTokenMapping[address(pToken)] = true;
    	emit createLog(address(pToken));
    }
}