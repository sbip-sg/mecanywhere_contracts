// SPDX-License-Identifier: MIT 
/*

Name: MecaTowerContract
Description: An on-chain Tower contract for MECAnywhere ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

import "./TowerAbstract.sol";

contract MecaTowerContract is MecaTowerAbstractContract
{
    // We have a list with all the tower and a mapping to check if a tower exists
    // and what is the position in the list of a tower (if it exists is index + 1, if not is 0)
    mapping(address => uint32) public towersIndex;
    Tower[] public towers;

    mapping(address => address[]) public towerPendingHosts;
    mapping(address => address[]) public towerActiveHosts;
    // custom modifiers

    // constructor

    constructor(
        uint256 towerInitialStake,
        uint256 hostRequestFee,
        uint256 failedTaskPenalty
    )
        MecaTowerAbstractContract(
            towerInitialStake,
            hostRequestFee,
            failedTaskPenalty
        )
    {
    }


    // External functions

    // External functions that are view
    
    // External functions that are pure

    // Public functions

    // Internal functions
    function _clear() internal override
    {
        // TODO: maybe go through tower as pops and delete them
        while (towers.length > 0) {
            uint256 stake = towers[towers.length - 1].stake;
            address payable towerOwner = towers[towers.length - 1].owner;
            uint256 pending_hosts = _deleteTower(towers[towers.length - 1].owner);
            stake += pending_hosts * HOST_REQUEST_FEE;
            if (stake > 0) {
                towerOwner.transfer(stake);
            }
        }
    }

    function _registerAsTower(
        Tower memory tower
    ) internal override {
        if (towersIndex[tower.owner] != 0) {
            revert();
        }
        towers.push(tower);
        towersIndex[tower.owner] = uint32(towers.length);
        towerActiveHosts[tower.owner] = new address[](0);
        towerPendingHosts[tower.owner] = new address[](0);
    }

    function _addStake(
        address tower_address,
        uint256 stake
    ) internal override {
        uint32 index = _getTowerIndex(tower_address);
        towers[index - 1].stake += stake;
    }

    function _removeStake(
        address tower_address,
        uint256 stake
    ) internal override {
        uint32 index = _getTowerIndex(tower_address);
        towers[index - 1].stake -= stake;
    }

    function _updateSizeLimit(
        address tower_address,
        uint256 newSizeLimit
    ) internal override {
        uint32 index = _getTowerIndex(tower_address);
        towers[index - 1].sizeLimit = newSizeLimit;
    }

    function _updatePublicConnection(
        address tower_address,
        string calldata newPublicConnection
    ) internal override {
        uint32 index = _getTowerIndex(tower_address);
        towers[index - 1].publicConnection = newPublicConnection;
    }

    function _updateFee(
        address tower_address,
        uint8 newFeeType,
        uint256 newFee
    ) internal override {
        uint32 index = _getTowerIndex(tower_address);
        towers[index - 1].fee = newFee;
        towers[index - 1].feeType = newFeeType;
    }

    function _deleteTower(
        address tower_address
    ) internal override returns (uint256) {
        uint32 index = _getTowerIndex(tower_address);
        Tower memory t = towers[index - 1];
        towers[index - 1] = towers[towers.length - 1];
        towersIndex[towers[index  - 1].owner] = index;
        towersIndex[t.owner] = 0;
        towers.pop();
        uint256 pending_hosts = towerPendingHosts[t.owner].length;
        delete towerActiveHosts[t.owner];
        delete towerPendingHosts[t.owner];
        return pending_hosts;
    }

    function _registerHostForTower(
        address tower_address,
        address host_address
    ) internal override {
        towerPendingHosts[tower_address].push(host_address);
    }

    function _acceptHost(
        address tower_address,
        address host_address
    ) internal override {
        for (uint256 i = 0; i < towerPendingHosts[tower_address].length; i++) {
            if (towerPendingHosts[tower_address][i] == host_address) {
                towerActiveHosts[tower_address].push(host_address);
                towerPendingHosts[tower_address][i] = towerPendingHosts[tower_address][towerPendingHosts[tower_address].length - 1];
                towerPendingHosts[tower_address].pop();
                return;
            }
        }
    }

    function _rejectHost(
        address tower_address,
        address host_address
    ) internal override {
        for (uint256 i = 0; i < towerPendingHosts[tower_address].length; i++) {
            if (towerPendingHosts[tower_address][i] == host_address) {
                towerPendingHosts[tower_address][i] = towerPendingHosts[tower_address][towerPendingHosts[tower_address].length - 1];
                towerPendingHosts[tower_address].pop();
                return;
            }
        }
    }

    function _deleteHost(
        address tower_address,
        address host_address
    ) internal override {
        for (uint256 i = 0; i < towerActiveHosts[tower_address].length; i++) {
            if (towerActiveHosts[tower_address][i] == host_address) {
                towerActiveHosts[tower_address][i] = towerActiveHosts[tower_address][towerActiveHosts[tower_address].length - 1];
                towerActiveHosts[tower_address].pop();
                return;
            }
        }
    }

    // Internal functions that are view

    function _getTower(
        address tower_address
    ) internal view override returns (Tower memory)
    {
        uint32 index = _getTowerIndex(tower_address);
        return towers[index - 1];
    }
    
    function _getTowerHosts(
        address tower_address
    ) internal view override returns (address[] memory)
    {
        return towerActiveHosts[tower_address];
    }
    
    function _getTowerPendingHosts(
        address tower_address
    ) internal view override returns (address[] memory)
    {
        return towerPendingHosts[tower_address];
    }

    function _getTowers(
    ) internal view override returns (Tower[] memory)
    {
        return towers;
    }

    // Private functions
    function _getTowerIndex(
        address tower_address
    ) private view returns (uint32)
    {
        uint32 index = towersIndex[tower_address];
        require(index > 0, "Tower does not exist");
        return index;
    }

}