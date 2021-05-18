require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
const config = require('./.private.json');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 6666
          }
        }
      }
    ]
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 21,
    enabled: (process.env.REPORT_GAS) ? true : false
  },
  networks: {
    ropsten: {
      url: `https://ropsten.infura.io/v3/${config.alchemy.ropsten.apiKey}`,
      accounts: [config.account.ropsten.key, config.account.ropsten.userA, config.account.ropsten.userB],
      gasPrice: 5e10
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${config.alchemy.mainnet.apiKey}`,
      accounts: [config.account.mainnet.key, config.account.mainnet.userA, config.account.mainnet.userB],
      gasPrice:45e9
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${config.alchemy.mainnet.apiKey}`,
      accounts: [config.account.mainnet.key, config.account.mainnet.userA, config.account.mainnet.userB],
      gasPrice:4e10
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "33VWZP4T5GYEYXSF7F65MZPTD1KPSFW8K6",
  }
};

