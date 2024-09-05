// SPDX-License-Identifier: MIT 
/*

Name: MecaHostContract
Description: An on-chain Host contract for MECAnywhere ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

import "./HostAbstract.sol";

contract MecaHostContract is MecaHostAbstractContract {
    // host -> task_ipfsSha256 -> task_fees
    mapping(address => mapping(bytes32 => HostTask)) hostTasks;

    // We have a list with all the hosts and a mapping to check if a host exists
    // and what is the position in the list of a host (if it exists is index + 1, if not is 0)
    mapping(address => uint32) public hostsIndex;
    Host[] public hosts;

    // custom modifiers

    // constructor

    constructor(
        uint256 hostRegisterFee,
        uint256 hostInitialStake,
        uint256 failedTaskPenalty,
        uint256 taskRegisterFee
    )
        MecaHostAbstractContract(
            hostRegisterFee,
            hostInitialStake,
            failedTaskPenalty,
            taskRegisterFee
        )
    {
    }

    // External functions

    // External functions that are view
    
    // External functions that are pure

    // Public functions

    // Internal functions

    function _clear() internal override {
    }

    function _addHost(
        Host memory host
    ) internal override {
        if (hostsIndex[host.owner] != 0) {
            revert();
        }
        hosts.push(host);
        hostsIndex[host.owner] = uint32(hosts.length);
    }

    function _addStake(
        address hostAddress,
        uint256 stake
    ) internal override {
        uint32 index = _getHostIndex(hostAddress);
        hosts[index - 1].stake += stake;
    }

    function _removeStake(
        address hostAddress,
        uint256 stake
    ) internal override {
        uint32 index = _getHostIndex(hostAddress);
        hosts[index - 1].stake -= stake;
    }

    function _updateBlockTimeoutLimit(
        address hostAddress,
        uint256 newBlockTimeoutLimit
    ) internal override {
        uint32 index = _getHostIndex(hostAddress);
        hosts[index - 1].blockTimeoutLimit = newBlockTimeoutLimit;
    }

    function _updatePublicKey(
        address hostAddress,
        bytes32[2] calldata newPublicKey
    ) internal override {
        uint32 index = _getHostIndex(hostAddress);
        hosts[index - 1].eccPublicKey = newPublicKey;
    }

    function _deleteHost(
        address hostAddress
    ) internal override  returns (uint256) {
        uint32 index = _getHostIndex(hostAddress);
        uint256 toPay = hosts[index - 1].stake;
        hosts[index - 1] = hosts[hosts.length - 1];
        hostsIndex[hosts[index - 1].owner] = index;
        hostsIndex[hostAddress] = 0;
        hosts.pop();
        return toPay;
    }

    function _addTask(
        address hostAddress,
        bytes32 ipfsSha256,
        HostTask memory task
    ) internal override {
        if (hostTasks[hostAddress][ipfsSha256].blockTimeout != 0) {
            revert();
        }
        hostTasks[hostAddress][ipfsSha256] = task;
    }

    function _updateTaskBlockTimeout(
        address hostAddress,
        bytes32 ipfsSha256,
        uint256 newBlockTimeout
    ) internal override {
        require(hostTasks[hostAddress][ipfsSha256].blockTimeout != 0);
        require(newBlockTimeout != 0);
        hostTasks[hostAddress][ipfsSha256].blockTimeout = newBlockTimeout;
    }

    function _updateTaskFee(
        address hostAddress,
        bytes32 ipfsSha256,
        uint256 newFee
    ) internal override {
        require(hostTasks[hostAddress][ipfsSha256].blockTimeout != 0);
        hostTasks[hostAddress][ipfsSha256].fee = newFee;
    }

    function _deleteTask(
        address hostAddress,
        bytes32 ipfsSha256
    ) internal override {
        require(hostTasks[hostAddress][ipfsSha256].blockTimeout != 0);
        delete hostTasks[hostAddress][ipfsSha256];
    }

    // Internal functions that are view

    function _getHost(
        address hostAddress
    )
        internal
        view
        override
        returns (Host memory)
    {
        uint32 index = _getHostIndex(hostAddress);
        return hosts[index - 1];
    }

    function _getHosts(
    )
        internal
        view
        override
        returns (Host[] memory)
    {
        return hosts;
    }

    function _getTask(
        address hostAddress,
        bytes32 ipfsSha256
    )
        internal
        view
        override
        returns (HostTask memory)
    {
        return hostTasks[hostAddress][ipfsSha256];
    }

    // Internal functions that are pure

    // Private functions

    function _getHostIndex(
        address hostAddress
    ) private view returns (uint32) {
        uint32 index = hostsIndex[hostAddress];
        require(index != 0, "Host does not exist");
        return index;
    }

}