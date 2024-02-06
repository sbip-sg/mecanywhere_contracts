const ganache = require("ganache");
const fs = require('fs');

const accounts_json = fs.readFileSync('./config/accounts.json');
const accounts_data = JSON.parse(accounts_json);

console.log(Object.entries(accounts_data));
accounts = Object.entries(accounts_data).map(
    ([key, value], i) => new Object({
      'secretKey': value.private_key,
      'balance': value.balance
    })
);
console.log(accounts);

const options = {'wallet': {'accounts': accounts}};
const server = ganache.server(options);
const PORT = 8545; // 0 means any available port
server.listen(PORT, async err => {
  if (err) throw err;

  console.log(`ganache listening on port ${server.address().port}...`);
  const provider = server.provider;
  const accounts = await provider.request({
    method: "eth_accounts",
    params: []
  });
});
