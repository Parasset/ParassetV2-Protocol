const hre = require("hardhat");
const { ethers } = require("hardhat");


const {deployUSDT,deployNEST,deployNestQuery,deployNTokenController,deployPriceController,deployInsurancePool,depolyFactory,deployMortgagePool} = require("./normal-scripts.js")

const {setInsurancePool,setMortgagePool,setAvg,setMaxRate,setK,setETHINS,setR0,setPriceController,setPTokenOperator,setFlag,setFlag2,setInfo,allow,setNTokenMapping} = require("./normal-scripts.js")

const {approve,createPtoken,coin,supplement,redemptionAll,decrease,increaseCoinage,reducedCoinage,exchangePTokenToUnderlying,exchangeUnderlyingToPToken,transfer,subscribeIns,redemptionIns} = require("./normal-scripts.js")

const {USDT,ETH,getPTokenAddress,getTokenInfo,getLedger,getFee,ERC20Balance,getInfoRealTime,getTotalSupply,getBalances,getInsurancePool} = require("./normal-scripts.js")


async function main() {
	const accounts = await ethers.getSigners();

	const ETHAddress = "0x0000000000000000000000000000000000000000";

	USDTContract = await deployUSDT();

	NESTContract = await deployNEST();

	FACTORY = await depolyFactory();

	PUSDMORPOOL = await deployMortgagePool(FACTORY.address);

	NESTQUARY = await deployNestQuery();

	NTOKENCONTROLLER = await deployNTokenController();

	PRICECONTROLLER = await deployPriceController(NESTQUARY.address, NTOKENCONTROLLER.address);

	PUSDINSPOOL = await deployInsurancePool(FACTORY.address, "PA-1", "PA-1");

	await setNTokenMapping(NTOKENCONTROLLER.address, NESTQUARY.address, USDTContract.address, NESTContract.address);
	await setAvg(NESTQUARY.address,USDTContract.address, USDT("2"));
	await setAvg(NESTQUARY.address,NESTContract.address, ETH("3"));

	await setPriceController(PUSDMORPOOL.address,PRICECONTROLLER.address);
	await setInsurancePool(PUSDMORPOOL.address, PUSDINSPOOL.address);
	await setMortgagePool(PUSDINSPOOL.address, PUSDMORPOOL.address);
	await setPTokenOperator(FACTORY.address, PUSDMORPOOL.address, "1");
	await setPTokenOperator(FACTORY.address, insurancePool.address, "1");
	await setFlag(PUSDMORPOOL.address, "1");
	await setFlag2(PUSDINSPOOL.address, "1");
	await createPtoken(FACTORY.address, "USDT");
	const USDTPToken = await getPTokenAddress(FACTORY.address, "0");
	await allow(PUSDMORPOOL.address, USDTPToken, ETHAddress);
	await allow(PUSDMORPOOL.address, USDTPToken, NESTContract.address);
	await setMaxRate(PUSDMORPOOL.address, ETHAddress, "70000");
	await setMaxRate(PUSDMORPOOL.address, NESTContract.address, "40000");
	await setK(PUSDMORPOOL.address, ETHAddress, "120000");
	await setK(PUSDMORPOOL.address, NESTContract.address, "130000");
	await setR0(PUSDMORPOOL.address, ETHAddress, "2000");
	await setR0(PUSDMORPOOL.address, NESTContract.address, "2000");
	await setInfo(PUSDMORPOOL.address, USDTContract.address, USDTPToken);
	await setInfo(PUSDINSPOOL.address, USDTContract.address, USDTPToken);
	
	console.log("network:rinkeby");
	console.log(`NestContract:${NESTContract.address}`);
	console.log(`USDTContract:${USDTContract.address}`);
	console.log(`PTokenFactory:${FACTORY.address}`);
	console.log(`MortgagePool-PUSD:${PUSDMORPOOL.address}`);
	console.log(`InsurancePool-PUSD:${PUSDINSPOOL.address}`);
	console.log(`PriceController:${PRICECONTROLLER.address}`);
	console.log(`NTokenController:${NTOKENCONTROLLER.address}`);
	console.log(`NestQuery:${NESTQUARY.address}`);
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