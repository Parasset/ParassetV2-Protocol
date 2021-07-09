const { ethers, upgrades } = require("hardhat");

const {ETHdec,USDTdec} = require("./normal-scripts.js")

const contracts = require("./contracts.js")

async function main() {

	const InsurancePool = await ethers.getContractFactory("InsurancePool");

	const PUSDINSPOOL = await upgrades.upgradeProxy(contracts.PUSDInsPool, InsurancePool);
	const PETHINSPOOL = await upgrades.upgradeProxy(contracts.PETHInsPool, InsurancePool);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});