from eth_account import Account
import json
import secrets
import pathlib

# Path: scripts/setup_accounts.py


def create_account() -> (str, str):
    private_key = "0x" + secrets.token_hex(32)
    account_address = Account.from_key(private_key).address
    return (private_key, account_address)


def main():
    accounts = dict()
    # MECA DAO, MECA Tower, MECA Host, MECA User, MECA Task developer
    accounts_names = [
        "meca_dao",
        "meca_tower",
        "meca_host",
        "meca_user",
        "meca_task"
    ]
    for account_name in accounts_names:
        private_key, account_address = create_account()
        accounts[account_name] = {
            "private_key": private_key,
            "account_address": account_address,
            "balance": 1000
        }
    with open(
            pathlib.Path(__file__).parent.parent / "config/accounts.json",
            "w") as f:
        json.dump(accounts, f, indent=4)


if __name__ == "__main__":
    main()
