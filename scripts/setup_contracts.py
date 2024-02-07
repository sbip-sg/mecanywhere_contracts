from eth_account import Account
import secrets
import web3
from web3.middleware import construct_sign_and_send_raw_middleware
from web3.middleware import geth_poa_middleware
from web3.exceptions import InvalidTransaction
import pathlib
from solcx import compile_source
import logging
import json
import multiformats_cid

logger = logging.getLogger(__name__)

# Path: scripts/setup_contracts.py


def add_contract_to_blockchain(
    w3: web3.Web3,
    private_key: str,
    contract_file_path: str,
    contract_name: str
) -> str:
    r"""
    Deploy the a contract to the blockchain

    Args:
        w3 : web3 instance
        private_key : private key of the account
        contract_file_path : path to the contract file
        contract_name : name of the contract
    """
    account = Account.from_key(private_key)

    # contracts path
    contract_file_path: pathlib.Path = pathlib.Path(
        contract_file_path).resolve().absolute()

    contracts_path = contract_file_path.parent

    # read the contract code
    contract_code = contract_file_path.read_text()

    # compile the contract
    compiled_sol = compile_source(
        contract_code,
        base_path=contracts_path,
        output_values=['abi', 'bin'],
        evm_version='shanghai')

    compiled_contract_name = f'<stdin>:{contract_name}'
    if compiled_contract_name not in compiled_sol:
        raise ValueError(
            f"Contract {contract_name} not found in the compiled contracts"
        )
    # get the contract abi
    contract_abi = compiled_sol[f'<stdin>:{contract_name}']['abi']
    # get the contract bytecode
    contract_bytecode = compiled_sol[f'<stdin>:{contract_name}']['bin']
    # deploy the contract
    contract = w3.eth.contract(
        abi=contract_abi,
        bytecode=contract_bytecode
    )

    gas_extra = 100000

    gas_estimate = contract.constructor().estimate_gas()

    # verify the balance
    account_balance = w3.eth.get_balance(account.address)

    if account_balance < (gas_estimate + gas_extra) * w3.eth.gas_price:
        raise ValueError(
            "Insufficient balance to deploy the contract"
        )

    gas_to_send = gas_estimate + gas_extra

    contract_transaction = contract.constructor().build_transaction({
        "from": account.address,
        "gas": gas_to_send,
        "nonce": w3.eth.get_transaction_count(account.address)
    })

    singed_contract_transaction = w3.eth.account.sign_transaction(
        contract_transaction, private_key
    )

    tx_hash = w3.eth.send_raw_transaction(
        singed_contract_transaction.rawTransaction
    )

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    contract_address = tx_receipt.contractAddress

    return contract_address


def get_contract_abi(
    contract_file_path: str,
    contract_name: str
) -> str:
    r"""
    Get the contract abi

    Args:
        contract_file_path : path to the contract file
        contract_name : name of the contract
    """
    # contracts path
    contract_file_path: pathlib.Path = pathlib.Path(
        contract_file_path).resolve().absolute()

    contracts_path = contract_file_path.parent

    # read the contract code
    contract_code = contract_file_path.read_text()

    # compile the contract
    compiled_sol = compile_source(
        contract_code,
        base_path=contracts_path,
        output_values=['abi'],
        evm_version='shanghai')

    compiled_contract_name = f'<stdin>:{contract_name}'
    if compiled_contract_name not in compiled_sol:
        raise ValueError(
            f"Contract {contract_name} not found in the compiled contracts"
        )
    # get the contract abi
    contract_abi = compiled_sol[f'<stdin>:{contract_name}']['abi']

    return contract_abi


def set_scheduler_to_dao(
    w3: web3.Web3,
    private_key: str,
    dao_contract: web3.contract.Contract,
    scheduler_contract_address: str
) -> bool:
    r"""
    Set scheduler to the dao

    Args:
        w3 : web3 instance
        private_key : private key of the account
        dao_contract : dao contract
        scheduler_contract_address : address of the scheduler contract
    """
    account = Account.from_key(private_key)

    gas_extra = 100000

    gas_estimate = dao_contract.functions.setSchedulerContract(
        scheduler_contract_address).estimate_gas()

    # verify the balance
    account_balance = w3.eth.get_balance(account.address)

    if account_balance < (gas_estimate + gas_extra) * w3.eth.gas_price:
        raise ValueError(
            "Insufficient balance to deploy the contract"
        )

    gas_to_send = gas_estimate + gas_extra

    set_scheduler_transaction = dao_contract.functions.setSchedulerContract(
        scheduler_contract_address).build_transaction({
            "from": account.address,
            "gas": gas_to_send,
            "nonce": w3.eth.get_transaction_count(account.address)
        })

    singed_set_scheduler_transaction = w3.eth.account.sign_transaction(
        set_scheduler_transaction, private_key
    )

    tx_hash = w3.eth.send_raw_transaction(
        singed_set_scheduler_transaction.rawTransaction
    )

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    return tx_receipt.status == 1


def set_contract_to_scheduler(
    w3: web3.Web3,
    private_key: str,
    scheduler_contract: web3.contract.Contract,
    contract_address: str,
    contract_type: int
) -> bool:
    r"""
    Set contract to the scheduler

    Args:
        w3 : web3 instance
        private_key : private key of the account
        scheduler_contract : scheduler contract
        contract_address : address of the contract
        contract_type : type of the contract (0: host, 1: tower, 2: task)
    """
    account = Account.from_key(private_key)

    gas_extra = 100000

    gas_estimate = scheduler_contract.functions.setTowerContract(
        contract_address).estimate_gas()

    # verify the balance
    account_balance = w3.eth.get_balance(account.address)

    if account_balance < (gas_estimate + gas_extra) * w3.eth.gas_price:
        raise ValueError(
            "Insufficient balance to deploy the contract"
        )

    gas_to_send = gas_estimate + gas_extra

    if contract_type == 0:
        set_transaction = scheduler_contract.functions.setHostContract(
            contract_address).build_transaction({
                "from": account.address,
                "gas": gas_to_send,
                "nonce": w3.eth.get_transaction_count(account.address)
            })
    elif contract_type == 1:
        set_transaction = scheduler_contract.functions.setTowerContract(
            contract_address).build_transaction({
                "from": account.address,
                "gas": gas_to_send,
                "nonce": w3.eth.get_transaction_count(account.address)
            })
    elif contract_type == 2:
        set_transaction = scheduler_contract.functions.setTaskContract(
            contract_address).build_transaction({
                "from": account.address,
                "gas": gas_to_send,
                "nonce": w3.eth.get_transaction_count(account.address)
            })
    else:
        raise ValueError(
            f"Invalid contract type {contract_type}"
        )

    singed_set_transaction = w3.eth.account.sign_transaction(
        set_transaction, private_key
    )

    tx_hash = w3.eth.send_raw_transaction(
        singed_set_transaction.rawTransaction
    )

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    return tx_receipt.status == 1


def register_tower(
    w3: web3.Web3,
    tower_private_key: str,
    tower_contract: web3.contract.Contract,
    size_limit: int,
    public_connection: str,
    fee: int,
    fee_type: int
) -> bool:
    r"""
    Register tower

    Args:
        w3 : web3 instance
        tower_private_key : private key of the tower account
        tower_contract : tower contract
        size_limit : size limit of the tower
        public_connection : public connection of the tower
        fee : fee of the tower
        fee_type : fee type of the tower (0: fixed, 1: size, 2: time, 3: size_time)
    """
    account = Account.from_key(tower_private_key)

    gas_extra = 100000

    gas_estimate = tower_contract.functions.registerTower(
        size_limit, public_connection, fee, fee_type).estimate_gas()
    
    # verify the balance
    account_balance = w3.eth.get_balance(account.address)

    if account_balance < (gas_estimate + gas_extra) * w3.eth.gas_price:
        raise ValueError(
            "Insufficient balance to deploy the contract"
        )
    
    gas_to_send = gas_estimate + gas_extra

    register_transaction = tower_contract.functions.registerTower(
        size_limit, public_connection, fee, fee_type).build_transaction({
            "from": account.address,
            "gas": gas_to_send,
            "nonce": w3.eth.get_transaction_count(account.address)
        })
    
    singed_register_transaction = w3.eth.account.sign_transaction(
        register_transaction, tower_private_key
    )

    tx_hash = w3.eth.send_raw_transaction(
        singed_register_transaction.rawTransaction
    )

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    return tx_receipt.status == 1


def register_host(
    w3: web3.Web3,
    host_private_key: str,
    host_contract: web3.contract.Contract,
    block_timeout_limit: int,
    public_key_type: int,
    public_key: str
) -> bool:
    r"""
    Register host

    Args:
        w3 : web3 instance
        host_private_key : private key of the host account
        host_contract : host contract
        block_timeout_limit : block timeout limit of the host
        public_key_type : public key type of the host (0: rsa, 1: ecc)
        public_key : public key of the host
    """
    account = Account.from_key(host_private_key)

    gas_extra = 100000

    gas_estimate = host_contract.functions.registerHost(
        public_key, public_key_type, block_timeout_limit).estimate_gas()
    
    # verify the balance
    account_balance = w3.eth.get_balance(account.address)

    if account_balance < (gas_estimate + gas_extra) * w3.eth.gas_price:
        raise ValueError(
            "Insufficient balance to deploy the contract"
        )
    
    gas_to_send = gas_estimate + gas_extra

    register_transaction = host_contract.functions.registerHost(
        public_key, public_key_type, block_timeout_limit).build_transaction({
            "from": account.address,
            "gas": gas_to_send,
            "nonce": w3.eth.get_transaction_count(account.address)
        })
    
    singed_register_transaction = w3.eth.account.sign_transaction(
        register_transaction, host_private_key
    )

    tx_hash = w3.eth.send_raw_transaction(
        singed_register_transaction.rawTransaction
    )

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    return tx_receipt.status == 1


def add_task(
    w3: web3.Web3,
    task_developer_private_key: str,
    task_contract: web3.contract.Contract,
    cid: str,
    fee: int,
    computing_type: int,
    size: int
) -> str:
    r"""
    Add task

    Args:
        w3 : web3 instance
        task_developer_private_key : private key of the task developer account
        task_contract : task contract
        cid : cid of the task
        fee : fee of the task
        computing_type : computing type of the task (0: cpu only, 1: cpu + gpu, 2: fpga, 3: asic)
        size : size of the task in memory of input and output
    """
    account = Account.from_key(task_developer_private_key)

    gas_extra = 100000

    # convert the cid to class
    cid = multiformats_cid.make_cid(cid)
    # encode in hex
    hex_cid_bytes = cid.encode("base16")
    hex_cid_hex_string = str(hex_cid_bytes)
    hex_cid_hex_string = hex_cid_hex_string[3:-1]
    cid_version = hex_cid_hex_string[:2]
    hex_cid_hex_string = hex_cid_hex_string[2:]
    cid_codec = hex_cid_hex_string[:2]
    hex_cid_hex_string = hex_cid_hex_string[2:]
    cid_multihash_type = hex_cid_hex_string[:2]
    hex_cid_hex_string = hex_cid_hex_string[2:]
    cid_multihash_length = hex_cid_hex_string[:2]
    hex_cid_hex_string = hex_cid_hex_string[2:]
    cid_multihash = hex_cid_hex_string
    if cid_version != "01":
        raise ValueError(
            "Invalid cid version"
        )
    if cid_codec != "70":
        raise ValueError(
            "Invalid cid codec"
        )
    # sha3
    if cid_multihash_type != "12":
        raise ValueError(
            "Invalid cid multihash type"
        )

    # 32 bytes
    if cid_multihash_length != "20":
        raise ValueError(
            "Invalid cid multihash length"
        )
    
    # verify length 32 bytes -> 64 hex caracters
    if len(cid_multihash) != 64:
        raise ValueError(
            "Invalid cid multihash string length"
        )

    gas_estimate = task_contract.functions.addTask(
        cid_multihash, fee, computing_type, size).estimate_gas()
    
    # verify the balance
    account_balance = w3.eth.get_balance(account.address)

    if account_balance < (gas_estimate + gas_extra) * w3.eth.gas_price:
        raise ValueError(
            "Insufficient balance to register the task"
        )
    
    gas_to_send = gas_estimate + gas_extra

    add_task_transaction = task_contract.functions.createTask(
        cid_multihash, fee, computing_type, size).build_transaction({
            "from": account.address,
            "gas": gas_to_send,
            "nonce": w3.eth.get_transaction_count(account.address)
        })
    
    singed_add_task_transaction = w3.eth.account.sign_transaction(
        add_task_transaction, task_developer_private_key
    )

    tx_hash = w3.eth.send_raw_transaction(
        singed_add_task_transaction.rawTransaction
    )

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    return tx_receipt.status == 1


def setup_contracts(endpoint_uri: str):

    # ge tthe current directory
    mod_path = pathlib.Path(__file__).parent.absolute()
    # Load accounts
    with open(
            mod_path.parent / "config" / "accounts.json",
            "r") as f:
        accounts = json.load(f)

    # load the meca dao account
    meca_dao_private_key = accounts["meca_dao"]["private_key"]
    meca_dao_account = Account.from_key(meca_dao_private_key)

    # Connect to the blockchain
    w3 = web3.Web3(web3.HTTPProvider(endpoint_uri=endpoint_uri))

    # add account
    # w3.middleware_onion.add(
    #    construct_sign_and_send_raw_middleware(meca_dao_account)
    # )

    # set the default account for making transactions
    # w3.eth.default_account = meca_dao_account.address

    # meca contracts path
    contracts_path = mod_path
    # meca primary dao contract
    dao_contract_path = (contracts_path / "MecaContract.sol").resolve()
    dao_contract_code = dao_contract_path.read_text()
    compiled_sol = compile_source(
        dao_contract_code,
        base_path=contracts_path,
        output_values=['abi', 'bin'],
        evm_version='shanghai')

    # get the contract abi
    dao_contract_abi = compiled_sol['<stdin>:MecaDaoContract']['abi']
    # get the contract bytecode
    dao_contract_bytecode = compiled_sol['<stdin>:MecaDaoContract']['bin']
    # deploy the contract
    dao_contract = w3.eth.contract(
        abi=dao_contract_abi,
        bytecode=dao_contract_bytecode
    )

    gas_extra = 100000

    gas_estimate = dao_contract.constructor().estimate_gas()

    # verify the balance
    account_balance = w3.eth.get_balance(meca_dao_account.address)
    if account_balance < (gas_estimate + gas_extra) * w3.eth.gas_price:
        raise ValueError(
            "Insufficient balance to deploy the contract"
        )

    gas_to_send = gas_estimate + gas_extra

    dao_contract_transaction = dao_contract.constructor().build_transaction({
        "from": meca_dao_account.address,
        "gas": gas_to_send,
        "nonce": w3.eth.get_transaction_count(meca_dao_account.address)
    })

    singed_dao_contract_transaction = w3.eth.account.sign_transaction(
        dao_contract_transaction, meca_dao_private_key
    )

    tx_hash = w3.eth.send_raw_transaction(
        singed_dao_contract_transaction.rawTransaction
    )

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    dao_contract_address = tx_receipt.contractAddress
    
