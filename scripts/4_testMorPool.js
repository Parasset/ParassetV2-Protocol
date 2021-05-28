const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deploy} = require("./deployContracts-scripts.js")
const {ETH, USDT, getLedger, getInfoRealTime} = require("./normal-scripts.js");

async function main() {
	
	const priceFee = "10000000000000000";
	contracts = await deploy();
	const accounts = await ethers.getSigners();
	const PUSDMorPool = contracts.PUSDMorPool;
	const PETHMorPool = contracts.PETHMorPool;
	const USDTContract = contracts.USDTContract;
	const NESTContract = contracts.NESTContract;
	const ETHAddress = "0x0000000000000000000000000000000000000000";

	await contracts.PUSD.approve(PUSDMorPool.address, ETH(9999999));
	await NESTContract.approve(PUSDMorPool.address, ETH(9999999));
	await PUSDMorPool.coin(NESTContract.address, ETH(10), 39, {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETH(3), ETH(2));
	console.log(`mortgageRate:${mortgageRate}`);
	await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETH(3), USDT(2), 40000, accounts[0].address);

	await PUSDMorPool.supplement(NESTContract.address, ETH(10), {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETH(3), ETH(2));
	console.log(`mortgageRate:${mortgageRate}`);

	await PUSDMorPool.decrease(NESTContract.address, ETH(10), {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETH(3), ETH(2));
	console.log(`mortgageRate:${mortgageRate}`);

	realInfo = await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETH(3), USDT(2), 40000, accounts[0].address);
	await PUSDMorPool.increaseCoinage(NESTContract.address, realInfo[3], {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETH(3), ETH(2));
	console.log(`mortgageRate:${mortgageRate}`);
	await getInfoRealTime(PUSDMorPool.address, NESTContract.address, ETH(3), USDT(2), 40000, accounts[0].address);

	await PUSDMorPool.reducedCoinage(NESTContract.address, ETH(1), {value:priceFee});
	ledger = await getLedger(PUSDMorPool.address, NESTContract.address, accounts[0].address);
	mortgageRate = await PUSDMorPool.getMortgageRate(ledger[0], ledger[1], ETH(3), ETH(2));
	console.log(`mortgageRate:${mortgageRate}`);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});