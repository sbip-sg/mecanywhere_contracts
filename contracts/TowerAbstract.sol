// SPDX-License-Identifier: MIT 
/*

Name: MecaHostAbstractContract
Description: An on-chain  abstract Host contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

abstract contract MecaTowerAbstractContract
{
    address public owner;

    struct tower {
        address owner;
        uint256 size_limit;
        string public_connection;
        uint8 fee_type;
        uint256 fee;
        uint256 stake;
    }

    constructor() 
    {
        owner = tx.origin;
    }

    function registerTower(
        uint256 size_limit,
        string calldata public_connection,
        uint256 fee,
        uint8 fee_type
    ) public payable virtual returns (bool);

    function deleteTower(
        address tower_address
    ) public virtual returns (bool);

    function updateTowerFee(
        uint256 fee,
        uint8 fee_type
    ) public virtual returns (bool);

    function getTowers(
    ) public view virtual returns (tower[] memory);

    function getTowerFee(
        address tower_address,
        uint256 size,
        uint256 block_timeout_limit
    ) public view virtual returns (uint256);

    function addStake(
    ) public payable virtual returns (bool);

    function getTowerSizeLimit(
        address tower_address
    ) public view virtual returns (uint256);

    function getTowerPublicConnection(
        address tower_address
    ) public view virtual returns (string memory);

    function getTowerStake(
        address tower_address
    ) public view virtual returns (uint256);

    function registerMeForTower(
        address tower_address
    ) public virtual returns (bool);

    function acceptHost(
        address host_address
    ) public virtual returns (bool);

    function acceptHosts(
        address[] calldata host_addresses
    ) public virtual returns (bool) {
        for (uint i = 0; i < host_addresses.length; i++) {
            acceptHost(host_addresses[i]);
        }
        return true;
    }

    function deleteHost(
        address host_address
    ) public virtual returns (bool);

    function getTowerHosts(
        address tower_address
    ) public view virtual returns (address[] memory);

    function getTowerPendingHosts(
        address tower_address
    ) public view virtual returns (address[] memory);

    function deleteTowerPendingHosts(
    ) public virtual returns (bool);
}