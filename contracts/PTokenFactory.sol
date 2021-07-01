// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./PToken.sol";
import "./iface/IPTokenFactory.sol";

contract PTokenFactory is IPTokenFactory {

	// Governance address
	address public _governance;
	// contract address => bool, ptoken operation permissions
	mapping(address=>bool) _allowAddress;
	// ptoken address => bool, ptoken verification
	mapping(address=>bool) _pTokenMapping;
    // 
    mapping(address=>bool) _governanceList;

    event createLog(address pTokenAddress);
    event pTokenOperator(address contractAddress, bool allow);

	constructor () public {
        _governance = msg.sender;
    }

    //---------modifier---------

    modifier onlyGovernance() {
        require(msg.sender == _governance, "Log:PTokenFactory:!gov");
        _;
    }

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
    /// @return governance address
    function getGovernance() override public view returns(address) {
        return _governance;
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

    /// @dev View governance rights
    /// @param add address to be tested
    /// @return bool
    function checkGovernance(address add) public view returns(bool) {
        return _governanceList[add];
    }

    //---------governance----------

    /// @dev Set governance address
    /// @param add new governance address
    function setGovernance(address add) public {
        require(checkGovernance(msg.sender), "Log:PTokenFactory:checkGovernance");
    	_governance = add;
    }

    /// @dev Set governance address
    /// @param contractAddress contract address
    /// @param allow bool
    function setPTokenOperator(address contractAddress, 
                               bool allow) public onlyGovernance {
        _allowAddress[contractAddress] = allow;
        emit pTokenOperator(contractAddress, allow);
    }

    /// @dev Add Governance
    /// @param add contract address
    /// @param allow bool
    function setGovernanceList(address add, bool allow) public {
        require(checkGovernance(msg.sender), "Log:PTokenFactory:checkGovernance");
        _governanceList[add] = allow;
    }

    /// @dev Create PToken
    /// @param name token name
    function createPtoken(string memory name) public onlyGovernance {
    	PToken pToken = new PToken(strConcat("PToken_", name), strConcat("P", name));
    	_pTokenMapping[address(pToken)] = true;
    	emit createLog(address(pToken));
    }
}