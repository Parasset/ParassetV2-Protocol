const { ethers, upgrades } = require("hardhat");

const {ETHdec,USDTdec} = require("./normal-scripts.js")

const contracts = require("./contracts.js")

async function main() {

	// const InsurancePool = await ethers.getContractFactory("InsurancePool");

	// await upgrades.upgradeProxy(contracts.PUSDInsPool, InsurancePool);
	// await upgrades.upgradeProxy(contracts.PETHInsPool, InsurancePool);

  const MortgagePool = await ethers.getContractFactory("MortgagePool");
  await upgrades.upgradeProxy(contracts.PUSDMorPool, MortgagePool);
  await upgrades.upgradeProxy(contracts.PETHMorPool, MortgagePool);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});