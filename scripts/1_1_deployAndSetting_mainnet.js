const hre = require("hardhat");
const { ethers } = require("hardhat");


const {deployUSDT,deployNEST,deployNestQuery,deployNTokenController,deployPriceController,deployInsurancePool,depolyFactory,deployMortgagePool} = require("./normal-scripts.js")

const {setInsurancePool,setMortgagePool,setAvg,setMaxRate,setLiquidationLine,setPriceController,setPTokenOperator,setFlag,setFlag2,setInfo,allow,setNTokenMapping} = require("./normal-scripts.js")

const {approve,createPtoken,coin,supplement,redemptionAll,decrease,increaseCoinage,reducedCoinage,exchangePTokenToUnderlying,exchangeUnderlyingToPToken,transfer,subscribeIns,redemptionIns} = require("./normal-scripts.js")

const {USDT,ETH,getPTokenAddress,getTokenInfo,getLedger,getFee,ERC20Balance,getInfoRealTime,getTotalSupply,getBalances,getInsurancePool} = require("./normal-scripts.js")

async function main() {
	const accounts = await ethers.getSigners();

	const ETHAddress = "0x0000000000000000000000000000000000000000";
	const NTokenControllerAdd = "0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62";
	const USDTContractAdd = "0xdac17f958d2ee523a2206206994597c13d831ec7";
	const NESTContractAdd = "0x04abEdA201850aC0124161F037Efd70c74ddC74C";
	const NestQueryAdd = "0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A";

	// factory = await depolyFactory();

	// pool = await deployMortgagePool(factory.address);

	// PriceController = await deployPriceController(NestQueryAdd, NTokenControllerAdd);

	// insurancePool = await deployInsurancePool(factory.address);


	factory = await ethers.getContractAt("PTokenFactory", "0xbe612b724B77038bC40A4E4A88335A93A9aA445B");

	pool = await ethers.getContractAt("MortgagePool", "0xd8E5EfE8DDbe78C8B08bdd70A6dc668F54a6C01c");

	PriceController = await ethers.getContractAt("PriceController", "0xd0a9FBFFB1EBa24Ae4A0C11B13FA9B26BF019548");

	insurancePool = await ethers.getContractAt("InsurancePool", "0xc80Ebc9eC1BB8DBC8e93D4C904372dD19786dc9C");


	await setInsurancePool(pool.address, insurancePool.address);

	await setMortgagePool(insurancePool.address, pool.address);

	await getInsurancePool(pool.address);

	// await createPtoken(factory.address, "USD");

	// await createPtoken(factory.address, "ETH");

	// await setPTokenOperator(factory.address, pool.address, "1");
	await setPTokenOperator(factory.address, insurancePool.address, "1");

	// await setFlag(pool.address, "1");
	await setFlag2(insurancePool.address, "1");

	const USDTPToken = await getPTokenAddress(factory.address, "0");

	const ETHPToken = await getPTokenAddress(factory.address, "1");;

	await allow(pool.address, USDTPToken, ETHAddress);

	await allow(pool.address, USDTPToken, NESTContractAdd);
	await allow(pool.address, ETHPToken, NESTContractAdd);

	await setMaxRate(pool.address, ETHAddress, "70");

	await setMaxRate(pool.address, NESTContractAdd, "40");

	await setLiquidationLine(pool.address, ETHAddress, "84");

	await setLiquidationLine(pool.address, NESTContractAdd, "75");

	await setPriceController(pool.address,PriceController.address);

	await setInfo(pool.address, USDTContractAdd, USDTPToken);
	await setInfo(pool.address, ETHAddress, ETHPToken);

	console.log("network:ropsten");
	console.log(`NestContract:${NESTContractAdd}`);
	console.log(`USDTContract:${USDTContractAdd}`);
	console.log(`PTokenFactory:${factory.address}`);
	console.log(`MortgagePool:${pool.address}`);
	console.log(`InsurancePool:${insurancePool.address}`);
	console.log(`PriceController:${PriceController.address}`);
	console.log(`NTokenController:${NTokenControllerAdd}`);
	console.log(`NestQuery:${NestQueryAdd}`);
	console.log(`PUSDT:${USDTPToken}`);
	console.log(`PETH:${ETHPToken}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});