const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deployUSDT,deployNEST,deployASET,depolyFactory,createPtoken,getPTokenAddress,deployNestQuery,deployNTokenController,setNTokenMapping,setAvg,ETH,USDT} = require("./normal-scripts.js")
const {deployMortgagePool,deployInsurancePool,deployPriceController,setPTokenOperator,setPriceController,setInsurancePool,setMortgagePool,setFlag,setFlag2,setETHINS,allow} = require("./normal-scripts.js")
const {setMaxRate,setK,setR0,setInfo,deployLPStakingMiningPool} = require("./normal-scripts.js")

exports.deploy = async function () {

	const accounts = await ethers.getSigners();
	const ETHAddress = "0x0000000000000000000000000000000000000000";
	// deploy USDT
	USDTContract = await deployUSDT();
	// deploy NEST
	NESTContract = await deployNEST();
	// deploy ASET
	ASETContract = await deployASET();
	// deploy USDT
	PTOKENFACTORY = await depolyFactory();
	// create PUSD
	await createPtoken(PTOKENFACTORY.address, "USD");
	// create PETH
	await createPtoken(PTOKENFACTORY.address, "ETH");
	USDTPToken = await getPTokenAddress(PTOKENFACTORY.address, "0");
	ETHPToken = await getPTokenAddress(PTOKENFACTORY.address, "1");
	// deploy nestQuary
	NESTQUARY = await deployNestQuery();
	// deploy ntokenController
	NTOKENCONTROLLER = await deployNTokenController();

	PUSDMORPOOL = await deployMortgagePool(PTOKENFACTORY.address);

	PETHMORPOOL = await deployMortgagePool(PTOKENFACTORY.address);

	PUSDINSPOOL = await deployInsurancePool(PTOKENFACTORY.address, "LP-USD", "LP-USD");

	PETHINSPOOL = await deployInsurancePool(PTOKENFACTORY.address, "LP-ETH", "LP-ETH");

	LPSTAKING = await deployLPStakingMiningPool(ASETContract.address);

	PRICECONTROLLER = await deployPriceController(NESTQUARY.address, NTOKENCONTROLLER.address);

	await setNTokenMapping(NTOKENCONTROLLER.address, NESTQUARY.address, USDTContract.address, NESTContract.address);
	await setAvg(NESTQUARY.address,USDTContract.address, USDT("2"));
	await setAvg(NESTQUARY.address,NESTContract.address, ETH("3"));

	await setPTokenOperator(PTOKENFACTORY.address, PUSDMORPOOL.address, "1");
	await setPTokenOperator(PTOKENFACTORY.address, PETHMORPOOL.address, "1");
	await setPTokenOperator(PTOKENFACTORY.address, PUSDINSPOOL.address, "1");
	await setPTokenOperator(PTOKENFACTORY.address, PETHINSPOOL.address, "1");

	await setPriceController(PUSDMORPOOL.address,PRICECONTROLLER.address);

	await setETHINS(PETHINSPOOL.address);

	await setInsurancePool(PUSDMORPOOL.address, PUSDINSPOOL.address);
	await setInsurancePool(PETHMORPOOL.address, PETHINSPOOL.address);
	await setMortgagePool(PUSDINSPOOL.address, PUSDMORPOOL.address);
	await setMortgagePool(PETHINSPOOL.address, PETHMORPOOL.address);

	await setFlag(PUSDMORPOOL.address, "1");
	await setFlag(PETHMORPOOL.address, "1");
	await setFlag2(PUSDINSPOOL.address, "1");
	await setFlag2(PETHINSPOOL.address, "1");

	await allow(PUSDMORPOOL.address, ETHAddress);
	await allow(PUSDMORPOOL.address, NESTContract.address);
	await allow(PETHMORPOOL.address, NESTContract.address);

	await setMaxRate(PUSDMORPOOL.address, ETHAddress, "70000");
	await setMaxRate(PUSDMORPOOL.address, NESTContract.address, "40000");
	await setMaxRate(PETHMORPOOL.address, NESTContract.address, "40000");

	await setK(PUSDMORPOOL.address, ETHAddress, "120000");
	await setK(PUSDMORPOOL.address, NESTContract.address, "130000");
	await setK(PETHMORPOOL.address, NESTContract.address, "130000");

	await setR0(PUSDMORPOOL.address, ETHAddress, "2000");
	await setR0(PUSDMORPOOL.address, NESTContract.address, "2000");
	await setR0(PETHMORPOOL.address, NESTContract.address, "2000");

	await setInfo(PUSDMORPOOL.address, USDTContract.address, USDTPToken);
	await setInfo(PUSDINSPOOL.address, USDTContract.address, USDTPToken);


	console.log(`USDTContract:"${USDTContract.address}",`);
	console.log(`NESTContract:"${NESTContract.address}",`);
	console.log(`ASETContract:"${ASETContract.address}",`);
	console.log(`PTokenFactory:"${PTOKENFACTORY.address}",`);
	console.log(`PUSD:"${USDTPToken}",`);
	console.log(`PETH:"${ETHPToken}",`);
	console.log(`NestQuery:"${NESTQUARY.address}",`);
	console.log(`NTokenController:"${NTOKENCONTROLLER.address}",`);
	console.log(`PUSDMorPool:"${PUSDMORPOOL.address}",`);
	console.log(`PETHMorPool:"${PETHMORPOOL.address}",`);
	console.log(`PUSDInsPool:"${PUSDINSPOOL.address}",`);
	console.log(`PETHInsPool:"${PETHINSPOOL.address}",`);
	console.log(`StakingMiningPool:"${LPSTAKING.address}",`);
	console.log(`PriceController:"${PRICECONTROLLER.address}",`);
	USDTPToken = await ethers.getContractAt("PToken", USDTPToken);
	ETHPToken = await ethers.getContractAt("PToken", ETHPToken);

	contracts = {
		USDTContract:USDTContract,
		NESTContract:NESTContract,
		ASETContract:ASETContract,
		PTokenFactory:PTOKENFACTORY,
		PUSD:USDTPToken,
		PETH:ETHPToken,
		NestQuery:NESTQUARY,
		NTokenController:NTOKENCONTROLLER,
		PUSDMorPool:PUSDMORPOOL,
		PETHMorPool:PETHMORPOOL,
		PUSDInsPool:PUSDINSPOOL,
		PETHInsPool:PETHINSPOOL,
		StakingMiningPool:LPSTAKING,
		PriceController:PRICECONTROLLER
	}

	return contracts;
}