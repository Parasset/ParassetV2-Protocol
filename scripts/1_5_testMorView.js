const { ethers } = require("hardhat");
const contracts = require("./contracts.js");
const {ETHdec, USDTdec, getLedger, getInfoRealTime} = require("./normal-scripts.js");

async function main() {
	const accounts = await ethers.getSigners();
	const USDT = await ethers.getContractFactory("USDT");
	const NEST = await ethers.getContractFactory("NEST");
	const PToken = await ethers.getContractFactory("PToken");
	const MortgagePool = await ethers.getContractFactory("MortgagePool");

	const USDTToken = await USDT.attach(contracts.USDTContract);
	const NESTToken = await NEST.attach(contracts.NESTContract);
	const PUSD = await PToken.attach(contracts.PUSD);
	const PUSDMorPool = await MortgagePool.attach(contracts.PUSDMorPool);

	await getLedger(PUSDMorPool.address, NESTToken.address, accounts[0].address);
	await getInfoRealTime(PUSDMorPool.address, NESTToken.address, ETHdec(3), USDTdec(2), 40000, accounts[0].address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});