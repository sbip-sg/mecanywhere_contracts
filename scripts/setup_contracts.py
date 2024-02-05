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

logger = logging.getLogger(__name__)

# Path: scripts/setup_contracts.py


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
    w3.middleware_onion.add(
        construct_sign_and_send_raw_middleware(meca_dao_account)
    )

    # set the default account for making transactions
    w3.eth.default_account = meca_dao_account.address
    # verify the balance
    account_balance = w3.eth.get_balance(meca_dao_account.address)
    logger.info("Account balance: %s", account_balance)

    # meca primary dao contract
    relative_path = (
        mod_path / "contracts" / "MecaContract.sol"
    ).resolve()
    sc_interface_code = relative_path.read_text()
    compiled_sol = compile_source(sc_interface_code, output_values=['abi'])
    contract_id, contract_interface = compiled_sol.popitem()
    abi = contract_interface['abi']
    provider_contract = web3_provider.eth.contract(
        address=provider_contract_address,
        abi=abi
    )

