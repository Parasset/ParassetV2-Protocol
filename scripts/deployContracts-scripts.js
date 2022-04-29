const { ethers, upgrades } = require("hardhat");

const {ETHdec,USDTdec} = require("./normal-scripts.js")

exports.deploy = async function () {

	const accounts = await ethers.getSigners();
	const ETHAddress = "0x0000000000000000000000000000000000000000";

	const USDT = await ethers.getContractFactory("USDT");
	const NEST = await ethers.getContractFactory("NEST");
	const ASET = await ethers.getContractFactory("ASET");
	const HBTC = await ethers.getContractFactory("HBTC");
	const ParassetGovernance = await ethers.getContractFactory("ParassetGovernance");
	const PTokenFactory = await hre.ethers.getContractFactory("PTokenFactory");
	const NestQuery = await ethers.getContractFactory("NestQuery");
	const NestBatchMining = await ethers.getContractFactory("NestBatchMining");
	const NTokenController = await ethers.getContractFactory("NTokenController");
	const MortgagePool = await ethers.getContractFactory("MortgagePool");
	const InsurancePool = await hre.ethers.getContractFactory("InsurancePool");
	const LPStakingMiningPool = await ethers.getContractFactory("LPStakingMiningPool");
	const PriceController = await ethers.getContractFactory("PriceController");
	const PriceController3 = await ethers.getContractFactory("PriceController3");
	

	// deploy USDT
	const USDTContract = await USDT.deploy();
	console.log(`1. USDT.deploy() + "${USDTContract.address}"`);
	// deploy NEST
	const NESTContract = await NEST.deploy();
	console.log(`2. NEST.deploy() + "${NESTContract.address}"`);
	// deploy ASET
	const ASETContract = await ASET.deploy();
	console.log(`3. ASET.deploy() + "${ASETContract.address}"`);
	// deploy HBTC
	const HBTCContract = await HBTC.deploy();
	console.log(`HBTC.deploy() + "${HBTCContract.address}"`);
	// deploy Governance
	const GovernanceContract = await ParassetGovernance.deploy();
	console.log(`4. ParassetGovernance + "${GovernanceContract.address}"`);
	// deploy Factory
	const PTOKENFACTORY = await upgrades.deployProxy(PTokenFactory, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`5. PTOKENFACTORY + "${PTOKENFACTORY.address}"`);
	// create PUSD
	await PTOKENFACTORY.createPToken("USD");
	console.log(`6. createPtoken success-USD"`);
	// create PETH
	await PTOKENFACTORY.createPToken("ETH");
	console.log(`7. createPtoken success-ETH"`);
	// create PBTC
	await PTOKENFACTORY.createPToken("BTC");
	console.log(`createPtoken success-BTC"`);

	sleep(1000);
	USDTPToken = await PTOKENFACTORY.getPTokenAddress(0);
	console.log(`8. USDTPToken + "${USDTPToken}"`);
	ETHPToken = await PTOKENFACTORY.getPTokenAddress(1);
	console.log(`9. ETHPToken + "${ETHPToken}"`);
	BTCPToken = await PTOKENFACTORY.getPTokenAddress(2);
	console.log(`BTCPToken + "${BTCPToken}"`);
	// deploy nestQuary
	NESTQUARY = await NestQuery.deploy();
	console.log(`NESTQUARY + ${NESTQUARY.address}`);
	NESTBATCHMINING = await NestBatchMining.deploy();
	console.log(`NESTBATCHMINING + ${NESTBATCHMINING.address}`);
	// deploy ntokenController
	NTOKENCONTROLLER = await NTokenController.deploy();
	console.log(`11. NTOKENCONTROLLER + "${NTOKENCONTROLLER.address}"`);

	PUSDMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`12. PUSDMORPOOL + "${PUSDMORPOOL.address}"`);
	PETHMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`13. PETHMORPOOL + "${PETHMORPOOL.address}"`);
	PBTCMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`PBTCMORPOOL + "${PBTCMORPOOL.address}"`);

	PUSDINSPOOL = await upgrades.deployProxy(InsurancePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`14. PUSDINSPOOL + "${PUSDINSPOOL.address}"`);
	PETHINSPOOL = await upgrades.deployProxy(InsurancePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`15. PETHINSPOOL + "${PETHINSPOOL.address}"`);
	PBTCINSPOOL = await upgrades.deployProxy(InsurancePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`PBTCINSPOOL + "${PBTCINSPOOL.address}"`);

	LPSTAKING = await upgrades.deployProxy(LPStakingMiningPool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`16. LPSTAKING + "${LPSTAKING.address}"`);
	PRICECONTROLLER = await PriceController.deploy(NESTQUARY.address, NTOKENCONTROLLER.address);
	console.log(`17. PRICECONTROLLER + "${PRICECONTROLLER.address}"`);
	PRICECONTROLLER3 = await PriceController3.deploy(NESTBATCHMINING.address, NESTQUARY.address);
	console.log(`PRICECONTROLLER3 + "${PRICECONTROLLER3.address}"`);

	// set ntokenmapping-test
	await NTOKENCONTROLLER.setNTokenMapping(USDTContract.address, NESTContract.address);
	console.log(`18. NTOKENCONTROLLER.setNTokenMapping`);
	// set price-test
	await NESTQUARY.setAvg(USDTContract.address, USDTdec("2500"));
	await NESTQUARY.setAvg(NESTContract.address, ETHdec("1000"));
	await NESTQUARY.setNTokenMapping(USDTContract.address, NESTContract.address);
	await NESTBATCHMINING.setAvg(0, '50000000000000000')
	console.log(`19. NESTQUARY.setAvg`);
	// set ptoken allow
	await PTOKENFACTORY.setPTokenOperator(PUSDMORPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PETHMORPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PBTCMORPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PUSDINSPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PETHINSPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PBTCINSPOOL.address, "1");
	console.log(`20. PTOKENFACTORY.setPTokenOperator`);
	// set ins&mor mapping
	await PUSDMORPOOL.setInsurancePool(PUSDINSPOOL.address);
	await PETHMORPOOL.setInsurancePool(PETHINSPOOL.address);
	await PBTCMORPOOL.setInsurancePool(PBTCINSPOOL.address);
	await PUSDINSPOOL.setMortgagePool(PUSDMORPOOL.address);
	await PETHINSPOOL.setMortgagePool(PETHMORPOOL.address);
	await PBTCINSPOOL.setMortgagePool(PBTCMORPOOL.address);
	console.log(`21. ins&mor mapping`);
	// set pricecontroller address
	await PUSDMORPOOL.setPriceController(PRICECONTROLLER.address);
	await PETHMORPOOL.setPriceController(PRICECONTROLLER.address);
	await PBTCMORPOOL.setPriceController(PRICECONTROLLER3.address);
	console.log(`22. setPriceController`);
	// set mor config
	await PUSDMORPOOL.setConfig(USDTPToken, "2400000", USDTContract.address, "1");
	await PETHMORPOOL.setConfig(ETHPToken, "2400000", ETHAddress, "1");
	await PBTCMORPOOL.setConfig(BTCPToken, "2400000", HBTCContract.address, "1");
	console.log(`23. setConfig`);
	// start ins
	await PETHINSPOOL.setFlag(1);
	await PUSDINSPOOL.setFlag(1);
	await PBTCINSPOOL.setFlag(1);
	await PETHINSPOOL.setTokenInfo("LP-ETH", "LP-ETH");
	await PUSDINSPOOL.setTokenInfo("LP-USD", "LP-USD");
	await PBTCINSPOOL.setTokenInfo("LP-BTC", "LP-BTC");
	await PETHINSPOOL.setInfo(ETHAddress, ETHPToken);
	await PUSDINSPOOL.setInfo(USDTContract.address, USDTPToken);
	await PBTCINSPOOL.setInfo(HBTCContract.address, BTCPToken);
	console.log(`24. start ins`);
	// set mor token info
	await PUSDMORPOOL.setMortgageAllow(ETHAddress, true);
	await PUSDMORPOOL.setMaxRate(ETHAddress, "70000");
	await PUSDMORPOOL.setK(ETHAddress, "120000");
	await PUSDMORPOOL.setR0(ETHAddress, "2000");
	await PUSDMORPOOL.setLiquidateRate(ETHAddress, "90000");
	await PUSDMORPOOL.setMortgageAllow(NESTContract.address, true);
	await PUSDMORPOOL.setMaxRate(NESTContract.address, "40000");
	await PUSDMORPOOL.setK(NESTContract.address, "133000");
	await PUSDMORPOOL.setR0(NESTContract.address, "2000");
	await PUSDMORPOOL.setLiquidateRate(NESTContract.address, "90000");
	console.log(`25. PUSDMORPOOL token info`);
	await PETHMORPOOL.setMortgageAllow(NESTContract.address, true);
	await PETHMORPOOL.setMaxRate(NESTContract.address, "40000");
	await PETHMORPOOL.setK(NESTContract.address, "133000");
	await PETHMORPOOL.setR0(NESTContract.address, "2000");
	await PETHMORPOOL.setLiquidateRate(NESTContract.address, "90000");
	console.log(`26. PETHMORPOOL token info`);
	await PBTCMORPOOL.setMortgageAllow(ETHAddress, true);
	await PBTCMORPOOL.setMaxRate(ETHAddress, "70000");
	await PBTCMORPOOL.setK(ETHAddress, "120000");
	await PBTCMORPOOL.setR0(ETHAddress, "2000");
	await PBTCMORPOOL.setLiquidateRate(ETHAddress, "90000");
	await PBTCMORPOOL.setMortgageAllow(NESTContract.address, true);
	await PBTCMORPOOL.setMaxRate(NESTContract.address, "40000");
	await PBTCMORPOOL.setK(NESTContract.address, "133000");
	await PBTCMORPOOL.setR0(NESTContract.address, "2000");
	await PBTCMORPOOL.setLiquidateRate(NESTContract.address, "90000");
	console.log(`PBTCMORPOOL token info`);
	// set reward token
	await LPSTAKING.setRewardsToken(ASETContract.address);
	console.log(`27. LPSTAKING.setRewardsToken`);
	// set staking address in ins
	await PUSDINSPOOL.setLPStakingMiningPool(LPSTAKING.address);
	await PETHINSPOOL.setLPStakingMiningPool(LPSTAKING.address);
	await PBTCINSPOOL.setLPStakingMiningPool(LPSTAKING.address);
	console.log(`28. INSPOOL.setLPStakingMiningPool`);

	console.log(`USDTContract:"${USDTContract.address}",`);
	console.log(`NESTContract:"${NESTContract.address}",`);
	console.log(`ASETContract:"${ASETContract.address}",`);
	console.log(`HBTCContract:"${HBTCContract.address}",`);
	console.log(`PTokenFactory:"${PTOKENFACTORY.address}",`);
	console.log(`PUSD:"${USDTPToken}",`);
	console.log(`PETH:"${ETHPToken}",`);
	console.log(`PBTC:"${BTCPToken}",`);
	console.log(`NestQuery:"${NESTQUARY.address}",`);
	console.log(`NestBatchMining:"${NESTBATCHMINING.address}",`);
	console.log(`NTokenController:"${NTOKENCONTROLLER.address}",`);
	console.log(`PUSDMorPool:"${PUSDMORPOOL.address}",`);
	console.log(`PETHMorPool:"${PETHMORPOOL.address}",`);
	console.log(`PBTCMorPool:"${PBTCMORPOOL.address}",`);
	console.log(`PUSDInsPool:"${PUSDINSPOOL.address}",`);
	console.log(`PETHInsPool:"${PETHINSPOOL.address}",`);
	console.log(`PBTCInsPool:"${PBTCINSPOOL.address}",`);
	console.log(`StakingMiningPool:"${LPSTAKING.address}",`);
	console.log(`PriceController:"${PRICECONTROLLER.address}",`);
	console.log(`PriceController3:"${PRICECONTROLLER3.address}",`);
	USDTPToken = await ethers.getContractAt("PToken", USDTPToken);
	ETHPToken = await ethers.getContractAt("PToken", ETHPToken);
	BTCPToken = await ethers.getContractAt("PToken", BTCPToken);

	contracts = {
		USDTContract:USDTContract,
		NESTContract:NESTContract,
		ASETContract:ASETContract,
		HBTCContract:HBTCContract,
		PTokenFactory:PTOKENFACTORY,
		PUSD:USDTPToken,
		PETH:ETHPToken,
		PBTC:BTCPToken,
		NestQuery:NESTQUARY,
		NestBatchMining:NESTBATCHMINING,
		NTokenController:NTOKENCONTROLLER,
		PUSDMorPool:PUSDMORPOOL,
		PETHMorPool:PETHMORPOOL,
		PBTCMorPool:PBTCMORPOOL,
		PUSDInsPool:PUSDINSPOOL,
		PETHInsPool:PETHINSPOOL,
		PBTCInsPool:PBTCINSPOOL,
		StakingMiningPool:LPSTAKING,
		PriceController:PRICECONTROLLER,
		PriceController3:PRICECONTROLLER3
	}

	return contracts;
}

function sleep(numberMillis) {
	var now = new Date();
	var exitTime = now.getTime() + numberMillis;
	while (true) {
		now = new Date();
		if (now.getTime() > exitTime){
			return;
		}
	}
}
