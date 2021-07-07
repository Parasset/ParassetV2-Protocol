const { ethers } = require("hardhat");
const contracts = require("./contracts.js");
const {ETHdec, USDTdec} = require("./normal-scripts.js");

async function main() {

	const priceFee = "10000000000000000";
	const USDT = await ethers.getContractFactory("USDT");
	const NEST = await ethers.getContractFactory("NEST");
	const PToken = await ethers.getContractFactory("PToken");
	const MortgagePool = await ethers.getContractFactory("MortgagePool");

	const USDTToken = await USDT.attach(contracts.USDTContract);
	const NESTToken = await NEST.attach(contracts.NESTContract);
	const PUSD = await PToken.attach(contracts.PUSD);
	const PUSDMorPool = await MortgagePool.attach(contracts.PUSDMorPool);

	// await NESTToken.approve(PUSDMorPool.address, ETHdec("9999999999"));
	// await PUSD.approve(PUSDMorPool.address, ETHdec("9999999999"));
	// console.log("approve success");

	// await PUSDMorPool.coin(NESTToken.address, ETHdec("2"), "40", {value:priceFee});
	// console.log("coin success");
	await PUSDMorPool.supplement(NESTToken.address, ETHdec("2"), {value:priceFee});
	await PUSDMorPool.increaseCoinage(NESTToken.address, ETHdec("1"), {value:priceFee});
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});