const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deploy} = require("./deployContracts-scripts.js")
const {ETHdec, USDTdec, getLedger, getInfoRealTime} = require("./normal-scripts.js");

async function main() {
	
	const priceFee = "2000000000000000";
	contracts = await deploy();
	const accounts = await ethers.getSigners();
	const PBTCMorPool = contracts.PBTCMorPool;
	const NESTContract = contracts.NESTContract;
	const ETHAddress = "0x0000000000000000000000000000000000000000";

	await contracts.PBTC.approve(PBTCMorPool.address, ETHdec(9999999));
	await NESTContract.approve(PBTCMorPool.address, ETHdec(9999999));
	await PBTCMorPool.coin(NESTContract.address, ETHdec(1000), 30000, {value:priceFee});
	ledger = await getLedger(PBTCMorPool.address, NESTContract.address, accounts[0].address);
	console.log('1')
	// mortgageRate = await PBTCMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	// console.log(`mortgageRate:${mortgageRate}`);
	// await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETHdec(3), USDTdec(2), 40000, accounts[0].address);
	
	await PBTCMorPool.supplement(NESTContract.address, ETHdec(500), {value:priceFee});
	ledger = await getLedger(PBTCMorPool.address, NESTContract.address, accounts[0].address);
	// mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	// console.log(`mortgageRate:${mortgageRate}`);
	console.log('2')
	await PBTCMorPool.decrease(NESTContract.address, ETHdec(400), {value:priceFee});
	ledger = await getLedger(PBTCMorPool.address, NESTContract.address, accounts[0].address);
	// mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	// console.log(`mortgageRate:${mortgageRate}`);
	console.log('3')

	realInfo = await getInfoRealTime(PBTCMorPool.address, NESTContract.address, ETHdec('1'), '62500000000000', 40000, accounts[0].address);
	await PBTCMorPool.increaseCoinage(NESTContract.address, realInfo[3], {value:priceFee});
	ledger = await getLedger(PBTCMorPool.address, NESTContract.address, accounts[0].address);
	// mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	// console.log(`mortgageRate:${mortgageRate}`);
	// await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETHdec(3), USDTdec(2), 40000, accounts[0].address);
	console.log('4')
	await PBTCMorPool.reducedCoinage(NESTContract.address, '1000000000000000', {value:priceFee});
	ledger = await getLedger(PBTCMorPool.address, NESTContract.address, accounts[0].address);
	// mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETHdec(3), ETHdec(2));
	// console.log(`mortgageRate:${mortgageRate}`);
	console.log('5')

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});