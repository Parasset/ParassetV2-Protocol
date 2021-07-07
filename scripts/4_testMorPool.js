const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deploy} = require("./deployContracts-scripts.js")
const {ETHdec, USDTdec, getLedger, getInfoRealTime} = require("./normal-scripts.js");

async function main() {
	
	const priceFee = "10000000000000000";
	contracts = await deploy();
	const accounts = await ethers.getSigners();
	const PUSDMorPool = contracts.PUSDMorPool;
	const PETHMorPool = contracts.PETHMorPool;
	const USDTContract = contracts.USDTContract;
	const NESTContract = contracts.NESTContract;
	const ETHAddress = "0x0000000000000000000000000000000000000000";

	await contracts.PUSD.approve(PUSDMorPool.address, ETHdec(9999999));
	await NESTContract.approve(PUSDMorPool.address, ETHdec(9999999));
	await PUSDMorPool.coin(NESTContract.address, ETHdec(10), 39, {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);

	if (ledger[0] * 2 / 3 * 0.39 == ledger[1]) {
		console.log("true");
	} else {console.log("wrong");}
	
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	console.log(`mortgageRate:${mortgageRate}`);
	await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETHdec(3), USDTdec(2), 40000, accounts[0].address);
	
	await PUSDMorPool.supplement(NESTContract.address, ETHdec(10), {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	console.log(`mortgageRate:${mortgageRate}`);

	await PUSDMorPool.decrease(NESTContract.address, ETHdec(10), {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	console.log(`mortgageRate:${mortgageRate}`);

	realInfo = await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETHdec(3), USDTdec(2), 40000, accounts[0].address);
	await PUSDMorPool.increaseCoinage(NESTContract.address, realInfo[3], {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	console.log(`mortgageRate:${mortgageRate}`);
	await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETHdec(3), USDTdec(2), 40000, accounts[0].address);

	await PUSDMorPool.reducedCoinage(NESTContract.address, ETHdec(1), {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	console.log(`mortgageRate:${mortgageRate}`);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});