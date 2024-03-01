// SPDX-License-Identifier: MIT 
/*

Name: MecaHostAbstractContract
Description: An on-chain  abstract Host contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

//import "./SchedulerAbstract.sol";

abstract contract MecaTowerAbstractContract {
    /// The owner of the contract
    address payable public owner;
    /// The initial stake for adding a tower
    uint256 immutable public TOWER_INITIAL_STAKE;
    /// The fee for requesting to be host to a tower
    uint256 immutable public HOST_REQUEST_FEE;
    /// The penalty for failed task
    uint256 immutable public FAILED_TASK_PENALTY;
    /// The scheduler contract address
    address public schedulerContractAddress;

    /**
    * @notice The Tower structure
    * @param owner The owner of the tower
    * @param sizeLimit The size limit of the tower
    * @param publicConnection The public connection of the tower
    * @param feeType The type of the fee (0: fixed / 1: size / 2: time / 3: size and time)
    * @param fee The fee of the tower
    * @param stake The stake of the tower
    */
    struct Tower {
        address payable owner;
        uint256 sizeLimit;
        string publicConnection;
        uint8 feeType;
        uint256 fee;
        uint256 stake;
    }
    // custom modifiers
    /**
    * @notice The onlyOwner modifier
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }
    /**
    * @notice The hasStake modifier
    */
    modifier hasStake() {
        require(msg.value >= TOWER_INITIAL_STAKE, "Minimum stake required");
        _;
    }
    /**
    * @notice The hasFee modifier
    */
    modifier hasFee() {
        require(msg.value == HOST_REQUEST_FEE, "Minimum fee required");
        _;
    }
    /**
    * @notice The onlyScheduler modifier
    */
    modifier onlyScheduler() {
        require(msg.sender == schedulerContractAddress, "Scheduler only");
        _;
    }

    // constructor

    /**
    * @notice The constructor
    * @param towerInitialStake The initial stake of a tower
    * @param hostRequestFee The fee for requesting to be host to a tower
    * @param failedTaskPenalty The penalty for failed task
    */
    constructor(
        uint256 towerInitialStake,
        uint256 hostRequestFee,
        uint256 failedTaskPenalty
    ) {
        owner = payable(tx.origin);
        TOWER_INITIAL_STAKE = towerInitialStake;
        HOST_REQUEST_FEE = hostRequestFee;
        FAILED_TASK_PENALTY = failedTaskPenalty;
        schedulerContractAddress = address(0);
    }

    // receive function

    /**
    * @notice The receive function
    */
    receive() external payable {
        revert();
    }

    // fallback function

    /**
    * @notice The fallback function
    */
    fallback() external payable {
        revert();
    }

    /**
    * @notice The clear function
    * @dev This function is used to clear the contract
    */
    function clear() external onlyOwner {
        _clear();
    }
    
    // External functions
    /**
    * @notice Set the scheduler contract address
    * @param newSchedulerContractAddress The new scheduler contract address
    * @dev This function is used only by the owner to set the scheduler contract address 
    */
    function setSchedulerContractAddress(
        address newSchedulerContractAddress
    ) 
        external 
        onlyOwner 
    {
        schedulerContractAddress = newSchedulerContractAddress;
    }

    /**
    * @notice penalty for failed task
    * @param towerAddress The address of the tower
    * @param userAddress The address of the user
    * @dev This function is used to penalize the tower for a failed task
    * and send the penalty to the user
    */
    function penaltyForFailedTask(
        address towerAddress,
        address userAddress
    ) 
        external 
        onlyScheduler 
    {
        _removeStake(towerAddress, FAILED_TASK_PENALTY);
        payable(userAddress).transfer(FAILED_TASK_PENALTY);
    }



    /**
    * @notice Register as a tower
    * @param sizeLimit The size limit of the tower
    * @param publicConnection The public connection of the tower
    * @param fee The fee of the tower
    * @param feeType The type of the fee (0: fixed / 1: size / 2: time / 3: size and time)
    * @dev This function is used to register as a tower the stake is inside the call
    */
    function registerAsTower(
        uint256 sizeLimit,
        string calldata publicConnection,
        uint256 fee,
        uint8 feeType
    ) 
        external
        payable
        hasStake
    {
        _registerAsTower(
            Tower({
                owner: payable(msg.sender),
                sizeLimit: sizeLimit,
                publicConnection: publicConnection,
                feeType: feeType,
                fee: fee,
                stake: msg.value
            })
        );

    }

    /**
    * @notice add a stake to the tower
    * @dev Only the tower can use this function for itself
    */
    function addStake() 
        external 
        payable 
    {
        _addStake(msg.sender, msg.value);
    }

    /**
    * @notice withdraw the money from the tower stake but
    * keeping the minimum stake
    * @dev Only the tower can use this function for itself
    * @param amount The amount to withdraw
    */
    function withdrawStake(
        uint256 amount
    ) 
        external 
    {
        // verify for overflows
        require(
            (_getTower(msg.sender).stake >=  amount) &&
            (_getTower(msg.sender).stake >= (TOWER_INITIAL_STAKE + amount)), "Minimum stake required");
        _removeStake(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }


    /**
    * @notice update the size limit of the tower
    * @dev Only the tower can use this function for itself
    */
    function updateSizeLimit(
        uint256 newSizeLimit
    ) 
        external 
    {
        _updateSizeLimit(msg.sender, newSizeLimit);
    }

    /**
    * @notice update the public connection of the tower
    * @dev Only the tower can use this function for itself
    */
    function updatePublicConnection(
        string calldata newPublicConnection
    ) 
        external 
    {
        _updatePublicConnection(msg.sender, newPublicConnection);
    }

    /**
    * @notice update the fee of the tower
    * @dev Only the tower can use this function for itself
    */
    function updateFee(
        uint8 newFeeType,
        uint256 newFee
    ) 
        external 
    {
        _updateFee(msg.sender, newFeeType, newFee);
    }

    /**
    * @notice delete the tower
    * @dev Only the tower can use this function for itself
    */
    function deleteTower() 
        external 
    {
        // check if the tower has the size limit 0
        Tower memory tower = _getTower(msg.sender);
        require(tower.sizeLimit == 0, "Size limit must be 0");
        // TODO: check if the tower has no running tasks
        // use schedulerContractAddress to check if the tower has no running tasks

        // compute the stake and delete the tower
        uint256 stake = tower.stake;
        uint256 pendingHosts = _deleteTower(msg.sender);
        stake += pendingHosts * HOST_REQUEST_FEE;

        // transfer the stake
        payable(msg.sender).transfer(stake);
    }

    /**
    * @notice register the sending host for the tower
    * @param towerAddress The address of the tower
    * @dev This function is used to register the sending host for the tower
    * The host must pay a fee
    */
    function registerMeForTower(
        address towerAddress
    ) 
        external
        payable
        hasFee
    {
        _registerHostForTower(towerAddress, msg.sender);
    }

    /**
    * @notice accept the host
    * @param hostAddress The address of the host
    * @dev This function is used to accept the host candidate
    * the tower gets the host fee
    */
    function acceptHost(
        address hostAddress
    ) 
        external
    {
        _acceptHost(msg.sender, hostAddress);
        payable(msg.sender).transfer(HOST_REQUEST_FEE);
    }

    /**
    * @notice reject the host
    * @param hostAddress The address of the host
    * @dev This function is used to reject the host candidate
    * the tower gets the host fee
    */
    function rejectHost(
        address hostAddress
    ) 
        external
    {
        _rejectHost(msg.sender, hostAddress);
        payable(msg.sender).transfer(HOST_REQUEST_FEE);
    }

    /**
    * @notice delete a host from the tower
    * @param hostAddress The address of the host
    * @dev This function is used to delete a host from the tower
    */
    function deleteHost(
        address hostAddress
    ) 
        external
    {
        _deleteHost(msg.sender, hostAddress);
    }

    // External functions that are view
    /**
    * @notice Get the tower size limit
    * @param towerAddress The address of the tower
    * @return uint256 The size limit of the tower
    */
    function getTowerSizeLimit(
        address towerAddress
    ) 
        external 
        view 
        returns (uint256)
    {
        return _getTower(towerAddress).sizeLimit;
    }

    /**
    * @notice Get the tower public connection
    * @param towerAddress The address of the tower
    * @return string The public connection of the tower
    */
    function getTowerPublicConnection(
        address towerAddress
    ) 
        external 
        view 
        returns (string memory)
    {
        return _getTower(towerAddress).publicConnection;
    }

    /**
    * @notice Get the tower fee
    * @param towerAddress The address of the tower
    * @param size The size of the task
    * @param blockTimeoutLimit The block timeout limit of the task
    * @return uint256 The fee of the tower
    */
    function getTowerFee(
        address towerAddress,
        uint256 size,
        uint256 blockTimeoutLimit
    ) 
        external 
        view 
        returns (uint256)
    {
        Tower memory tower = _getTower(towerAddress);
        uint8 feeType = tower.feeType;
        uint256 fee = tower.fee;
        if (feeType == 0) {
            return fee;
        } else if (feeType == 1) {
            return fee * size;
        } else if (feeType == 2) {
            return fee * blockTimeoutLimit;
        } else if (feeType == 3) {
            return fee * size * blockTimeoutLimit;
        } else {
            return 0;
        }
    }

    /**
    * @notice Get the tower stake
    * @param towerAddress The address of the tower
    * @return uint256 The stake of the tower
    */
    function getTowerStake(
        address towerAddress
    ) 
        external 
        view 
        returns (uint256)
    {
        return _getTower(towerAddress).stake;
    }


    /**
    * @notice Get the tower hosts
    * @param towerAddress The address of the tower
    * @return address[] The hosts of the tower
    */
    function getTowerHosts(
        address towerAddress
    ) 
        external 
        view 
        returns (address[] memory)
    {
        return _getTowerHosts(towerAddress);
    }

    /**
    * @notice Get the tower pending hosts
    * @param towerAddress The address of the tower
    * @return address[] The pending hosts of the tower
    */
    function getTowerPendingHosts(
        address towerAddress
    ) 
        external 
        view 
        returns (address[] memory)
    {
        return _getTowerPendingHosts(towerAddress);
    }

    /**
    * @notice Get the towers
    * @return tower[] The towers
    */
    function getTowers(
    ) 
        external 
        view 
        returns (Tower[] memory)
    {
        return _getTowers();
    }
    
    // External functions that are pure

    // Public functions

    // Internal functions

    /**
    * @notice The clear function
    */
    function _clear() internal virtual;

    /**
    * @notice register a tower
    * @param tower The tower to register
    */
    function _registerAsTower(
        Tower memory tower
    ) internal virtual;

    /**
    * @notice add a stake to the tower
    * @param towerAddress The address of the tower
    * @param stake The stake to add
    */
    function _addStake(
        address towerAddress,
        uint256 stake
    ) internal virtual;

    /**
    * @notice remove the money from the tower stake
    * @param towerAddress The address of the tower
    * @param amount The amount to withdraw
    */
    function _removeStake(
        address towerAddress,
        uint256 amount
    ) internal virtual;

    /**
    * @notice update the size limit of the tower
    * @param towerAddress The address of the tower
    * @param newSizeLimit The new size limit
    */
    function _updateSizeLimit(
        address towerAddress,
        uint256 newSizeLimit
    ) internal virtual;

    /**
    * @notice update the public connection of the tower
    * @param towerAddress The address of the tower
    * @param newPublicConnection The new public connection
    */
    function _updatePublicConnection(
        address towerAddress,
        string calldata newPublicConnection
    ) internal virtual;


    /**
    * @notice update the fee of the tower
    * @param towerAddress The address of the tower
    * @param newFeeType The new fee type
    * @param newFee The new fee
    */
    function _updateFee(
        address towerAddress,
        uint8 newFeeType,
        uint256 newFee
    ) internal virtual;

    /**
    * @notice delete the tower
    * @param towerAddress The address of the tower
    */
    function _deleteTower(
        address towerAddress
    ) internal virtual returns (uint256);

    /**
    * @notice register the sending host for the tower
    * @param towerAddress The address of the tower
    * @param hostAddress The address of the host
    */
    function _registerHostForTower(
        address towerAddress,
        address hostAddress
    ) internal virtual;

    /**
    * @notice accept the host
    * @param towerAddress The address of the tower
    * @param hostAddress The address of the host
    */
    function _acceptHost(
        address towerAddress,
        address hostAddress
    ) internal virtual;

    /**
    * @notice reject the host
    * @param towerAddress The address of the tower
    * @param hostAddress The address of the host
    */
    function _rejectHost(
        address towerAddress,
        address hostAddress
    ) internal virtual;

    /**
    * @notice delete a host from the tower
    * @param towerAddress The address of the tower
    * @param hostAddress The address of the host
    */
    function _deleteHost(
        address towerAddress,
        address hostAddress
    ) internal virtual;

    // Internal functions that are view

    /**
    * @notice Get the tower
    * @param towerAddress The address of the tower
    * @return Tower The tower
    */
    function _getTower(
        address towerAddress
    ) 
        internal 
        view 
        virtual 
        returns (Tower memory);
    
    /**
    * @notice Get the tower hosts
    * @param towerAddress The address of the tower
    * @return address[] The hosts of the tower
    */
    function _getTowerHosts(
        address towerAddress
    ) 
        internal 
        view 
        virtual 
        returns (address[] memory);

    
    /**
    * @notice Get the tower pending hosts
    * @param towerAddress The address of the tower
    * @return address[] The pending hosts of the tower
    */
    function _getTowerPendingHosts(
        address towerAddress
    ) 
        internal 
        view 
        virtual 
        returns (address[] memory);
    
    /**
    * @notice Get the towers
    * @return tower[] The towers
    */
    function _getTowers(
    ) 
        internal 
        view 
        virtual 
        returns (Tower[] memory);

    // Private functions
}