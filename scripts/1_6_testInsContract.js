const { ethers } = require("hardhat");
const contracts = require("./contracts.js");
const {ETHdec, USDTdec} = require("./normal-scripts.js");

async function main() {

	const priceFee = "10000000000000000";
	const USDT = await ethers.getContractFactory("USDT");
	const PToken = await ethers.getContractFactory("PToken");
	const InsurancePool = await ethers.getContractFactory("InsurancePool");

	const USDTToken = await USDT.attach(contracts.USDTContract);
	const PUSD = await PToken.attach(contracts.PUSD);
	const PUSDIns = await InsurancePool.attach(contracts.PUSDInsPool);

	// await PUSD.approve(PUSDIns.address, ETHdec("9999999999"));
	// await USDTToken.approve(PUSDIns.address, USDTdec("9999999999"));
	// console.log("approve success");

	await PUSDIns.subscribeIns(USDTdec("10"));
	console.log("subscribeIns success");

	await PUSDIns.exchangePTokenToUnderlying(ETHdec("1"));
	console.log("exchangePTokenToUnderlying success");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});