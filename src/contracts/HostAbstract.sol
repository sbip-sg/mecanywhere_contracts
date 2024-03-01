// SPDX-License-Identifier: MIT 
/*

Name: MecaHostAbstractContract
Description: An on-chain  abstract Host contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;


abstract contract MecaHostAbstractContract {
    /// The owner of the contract
    address payable public owner;
    /// The register host fee
    uint256 immutable public HOST_REGISTER_FEE;
    /// The task register fee
    uint256 immutable public TASK_REGISTER_FEE;
    /// The initial stake for a host
    uint256 immutable public HOST_INITIAL_STAKE;
    /// The failed task fee
    uint256 immutable public FAILED_TASK_PENALTY;
    /// The scheduler contract address
    address public schedulerContractAddress;

    /**
    * @notice The Task information from a host
    * @param blockTimeout The block timeout of the task
    * @param fee The fee of the task
    */
    struct HostTask {
        uint256 blockTimeout;
        uint256 fee;
    }

    /**
    * @notice The Host structure
    * @param owner The owner of the host
    * @param eccPublicKey The ECC public key of the host
    * @param blockTimeoutLimit The block timeout limit of the host
    * @param stake The stake of the host
    */
    struct Host {
        address payable owner;
        bytes32[2] eccPublicKey;
        uint256 blockTimeoutLimit;
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
        require(msg.value >= HOST_INITIAL_STAKE, "Minimum stake required");
        _;
    }
    /**
    * @notice The hasFee modifier
    */
    modifier hasFee() {
        require(msg.value == HOST_REGISTER_FEE, "Minimum fee required");
        _;
    }
    /**
    * @notice The hasFee modifier
    */
    modifier hasTaskFee() {
        require(msg.value == TASK_REGISTER_FEE, "Minimum task fee required");
        _;
    }
    /**
    * @notice The onlyScheduler modifier
    */
    modifier onlyScheduler() {
        require(msg.sender == schedulerContractAddress, "Scheduler only");
        _;
    }
    /**
    * @notice Existing task modifier
    */
    modifier existingTask(
        bytes32 ipfsSha256
    ) {
        require(
            _getTask(msg.sender, ipfsSha256).blockTimeout > 0,
            "Task not found"
        );
        _;
    }

    /**
    * @notice The constructor
    * @param hostRegisterFee The fee for registering a host
    * @param hostInitialStake The initial stake for a host
    * @param failedTaskPenalty The penalty for a failed task
    * @param taskRegisterFee The fee for registering a task
    */
    constructor(
        uint256 hostRegisterFee,
        uint256 hostInitialStake,
        uint256 failedTaskPenalty,
        uint256 taskRegisterFee
    ) {
        owner = payable(tx.origin);
        HOST_REGISTER_FEE = hostRegisterFee;
        HOST_INITIAL_STAKE = hostInitialStake;
        FAILED_TASK_PENALTY = failedTaskPenalty;
        TASK_REGISTER_FEE = taskRegisterFee;
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
    * @notice The registerAsHost function
    * @param publicKey The ecc public key of the host
    * @param blockTimeoutLimit The block timeout limit of the host
    */
    function registerAsHost(
        bytes32[2] calldata publicKey,
        uint256 blockTimeoutLimit
    )
        external
        payable
        hasStake
    {
        _addHost(
            Host({
                owner: payable(msg.sender),
                eccPublicKey: publicKey,
                blockTimeoutLimit: blockTimeoutLimit,
                stake: msg.value
            })
        );
    }

    /**
    * @notice The addStake function
    * @dev This function is used to add stake to the host
    */
    function addStake()
        external
        payable
    {
        _addStake(msg.sender, msg.value);
    }


    /**
    * @notice The widthdrawStake function
    * @param amount The amount to widthdraw
    */
    function widthdrawStake(
        uint256 amount
    )
        external
    {
        require(
            (_getHost(msg.sender).stake >= amount) &&
            (_getHost(msg.sender).stake - amount >= HOST_INITIAL_STAKE),
            "Invalid amount"
        );
        _removeStake(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    /**
    * @notice The updateBlockTimeoutLimit function
    * @param newBlockTimeoutLimit The new block timeout limit
    */
    function updateBlockTimeoutLimit(
        uint256 newBlockTimeoutLimit
    )
        external
    {
        _updateBlockTimeoutLimit(msg.sender, newBlockTimeoutLimit);
    }

    /**
    * @notice The updatePublicKey function
    * @param newPublicKey The new ecc public key
    */
    function updatePublicKey(
        bytes32[2] calldata newPublicKey
    )
        external
    {
        _updatePublicKey(msg.sender, newPublicKey);
    }

    /**
    * @notice The deleteHost function
    */
    function deleteHost()
        external
    {
        Host memory host = _getHost(msg.sender);
        require(host.blockTimeoutLimit == 0, "Host can get tasks");

        // TODO: verify of any active tasks

        uint256 stake = _deleteHost(msg.sender);
        payable(msg.sender).transfer(stake);
    }

    /**
    * @notice The setSchedulerContractAddress function
    * @param newSchedulerContractAddress The new scheduler contract address
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
    * @param hostAddress The address of the host
    * @param userAddress The address of the user
    * @dev This function is used to penalize the host for a failed task
    * and send the penalty to the user
    */
    function penaltyForFailedTask(
        address hostAddress,
        address userAddress
    ) 
        external 
        onlyScheduler 
    {
        _removeStake(hostAddress, FAILED_TASK_PENALTY);
        payable(userAddress).transfer(FAILED_TASK_PENALTY);
    }

    /**
    * @notice Add a task to the host
    * @param ipfsSha256 The IPFS hash of the task
    * @param blockTimeout The block timeout of the task
    * @param fee The fee of the task
    */
    function addTask(
        bytes32 ipfsSha256,
        uint256 blockTimeout,
        uint256 fee
    )
        external
        payable
        hasTaskFee
    {
        require(blockTimeout > 0, "Invalid block timeout limit");
        require(_getTask(msg.sender, ipfsSha256).blockTimeout == 0, "Task already exists");
        _addTask(
            msg.sender,
            ipfsSha256,
            HostTask({
                blockTimeout: blockTimeout,
                fee: fee
            })
        );
    }

    /**
    * @notice The updateTaskBlockTimeout function
    * @param ipfsSha256 The IPFS hash of the task
    * @param newBlockTimeout The new block timeout of the task
    */
    function updateTaskBlockTimeout(
        bytes32 ipfsSha256,
        uint256 newBlockTimeout
    )
        external
        existingTask(ipfsSha256)
    {
        require(
            newBlockTimeout > 0,
            "Invalid block timeout limit"
        );
        _updateTaskBlockTimeout(msg.sender, ipfsSha256, newBlockTimeout);
    }

    /**
    * @notice The update task fee function
    * @param ipfsSha256 The IPFS hash of the task
    * @param newFee The new fee of the task
    */
    function updateTaskFee(
        bytes32 ipfsSha256,
        uint256 newFee
    )
        external
        existingTask(ipfsSha256)
    {
        _updateTaskFee(msg.sender, ipfsSha256, newFee);
    }

    /**
    * @notice The deleteTask function
    * @param ipfsSha256 The IPFS hash of the task
    */
    function deleteTask(
        bytes32 ipfsSha256
    )
        external
        existingTask(ipfsSha256)
    {
        _deleteTask(msg.sender, ipfsSha256);
        payable(msg.sender).transfer(TASK_REGISTER_FEE);
    }

    // External functions that are view

    /**
    * @notice The get the host public key
    * @param hostAddress The address of the host
    * @return bytes32[2] The public key of the host
    */
    function getHostPublicKey(
        address hostAddress
    )
        external
        view
        returns (bytes32[2] memory)
    {
        return _getHost(hostAddress).eccPublicKey;
    }

    /**
    * @notice The get the host block timeout limit
    * @param hostAddress The address of the host
    * @return uint256 The block timeout limit of the host
    */
    function getHostBlockTimeoutLimit(
        address hostAddress
    )
        external
        view
        returns (uint256)
    {
        return _getHost(hostAddress).blockTimeoutLimit;
    }

    /**
    * @notice The get the host stake
    * @param hostAddress The address of the host
    * @return uint256 The stake of the host
    */
    function getHostStake(
        address hostAddress
    )
        external
        view
        returns (uint256)
    {
        return _getHost(hostAddress).stake;
    }

    /**
    * @notice The get the hosts
    * @return Host[] The hosts
    */
    function getHosts(
    )
        external
        view
        returns (Host[] memory)
    {
        return _getHosts();
    }

    /**
    * @notice The get the task block timeout
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @return uint256 The block timeout of the task
    */
    function getTaskBlockTimeout(
        address hostAddress,
        bytes32 ipfsSha256
    )
        external
        view
        returns (uint256)
    {
        return _getTask(hostAddress, ipfsSha256).blockTimeout;
    }

    /**
    * @notice The get the task fee
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @return uint256 The fee of the task
    */
    function getTaskFee(
        address hostAddress,
        bytes32 ipfsSha256
    )
        external
        view
        returns (uint256)
    {
        return _getTask(hostAddress, ipfsSha256).fee;
    }
    
    // External functions that are pure

    // Public functions

    // Internal functions

    /**
    * @notice The clear function
    */
    function _clear() internal virtual;

    /**
    * @notice The addHost function
    * @param host The host to be added
    */
    function _addHost(
        Host memory host
    ) internal virtual;

    /**
    * @notice The addStake function
    * @param hostAddress The address of the host
    * @param stake The stake to be added
    */
    function _addStake(
        address hostAddress,
        uint256 stake
    ) internal virtual;

    /**
    * @notice The removeStake function
    * @param hostAddress The address of the host
    * @param stake The stake to be removed
    */
    function _removeStake(
        address hostAddress,
        uint256 stake
    ) internal virtual;

    /**
    * @notice The updateBlockTimeoutLimit function
    * @param hostAddress The address of the host
    * @param newBlockTimeoutLimit The new block timeout limit
    */
    function _updateBlockTimeoutLimit(
        address hostAddress,
        uint256 newBlockTimeoutLimit
    ) internal virtual;

    /**
    * @notice The updatePublicKey function
    * @param hostAddress The address of the host
    * @param newPublicKey The new public key
    */
    function _updatePublicKey(
        address hostAddress,
        bytes32[2] calldata newPublicKey
    ) internal virtual;

    /**
    * @notice The deleteHost function
    * @param hostAddress The address of the host
    */
    function _deleteHost(
        address hostAddress
    ) internal virtual returns (uint256);

    /**
    * @notice The addTask function
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @param task The task to be added
    */
    function _addTask(
        address hostAddress,
        bytes32 ipfsSha256,
        HostTask memory task
    ) internal virtual;

    /**
    * @notice The updateTaskBlockTimeout function
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @param newBlockTimeout The new block timeout of the task
    */
    function _updateTaskBlockTimeout(
        address hostAddress,
        bytes32 ipfsSha256,
        uint256 newBlockTimeout
    ) internal virtual;

    /**
    * @notice The updateTaskFee function
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @param newFee The new fee of the task
    */
    function _updateTaskFee(
        address hostAddress,
        bytes32 ipfsSha256,
        uint256 newFee
    ) internal virtual;

    /**
    * @notice The deleteTask function
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    */
    function _deleteTask(
        address hostAddress,
        bytes32 ipfsSha256
    ) internal virtual;

    // Internal functions that are view

    /**
    * @notice The get the host
    * @param hostAddress The address of the host
    * @return Host The host
    */
    function _getHost(
        address hostAddress
    )
        internal
        view
        virtual
        returns (Host memory);
    
    /**
    * @notice The get the hosts
    * @return Host[] The hosts
    */
    function _getHosts(
    )
        internal
        view
        virtual
        returns (Host[] memory);

    /**
    * @notice The get the task
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @return HostTask The task
    */
    function _getTask(
        address hostAddress,
        bytes32 ipfsSha256
    )
        internal
        view
        virtual
        returns (HostTask memory);
    // Private functions

}