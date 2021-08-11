const { ethers, upgrades } = require("hardhat");

const {ETHdec,USDTdec} = require("./normal-scripts.js")

async function main() {

	const accounts = await ethers.getSigners();
	const ETHAddress = "0x0000000000000000000000000000000000000000";
    console.log(1111)
	const USDT = await ethers.getContractFactory("USDT");
	const NEST = await ethers.getContractFactory("NEST");
	const ASET = await ethers.getContractFactory("ASET");
	const ParassetGovernance = await ethers.getContractFactory("ParassetGovernance");
	const PTokenFactory = await hre.ethers.getContractFactory("PTokenFactory");
	const NestQuery = await ethers.getContractFactory("NestQuery");
	const NTokenController = await ethers.getContractFactory("NTokenController");
	const MortgagePool = await ethers.getContractFactory("MortgagePool");
	const InsurancePool = await hre.ethers.getContractFactory("InsurancePool");
	const LPStakingMiningPool = await ethers.getContractFactory("LPStakingMiningPool");
	const PriceController = await ethers.getContractFactory("PriceController");


	// deploy USDT
	const USDTContract = await USDT.attach('0x813369c81AfdB2C84fC5eAAA38D0a64B34BaE582');
	// deploy NEST
	const NESTContract = await NEST.attach('0x2Eb7850D7e14d3E359ce71B5eBbb03BbE732d6DD');
	// deploy ASET
	const ASETContract = await ASET.attach('0xBA00239Dc53282207e2101CE78c70ca9E0592b57');
	// deploy Governance
	const GovernanceContract = await ParassetGovernance.attach('0xFfA0a9E299419acCf0b467017409BB3F6Bc25dEF');
	// deploy Factory
	const PTOKENFACTORY = await PTokenFactory.attach('0xdae16494Bf95085Efac4aaF238cC3d6eFd23C7A5');
    PUSDINSPOOL = await InsurancePool.attach('0x42B753b2D2409CA6C0C5B6d300Cfa85094e730a4');
	PETHINSPOOL = await InsurancePool.attach('0x7a5b47F79424dB6A161c65df49F906e9c5BE9A02');

	LPSTAKING = await LPStakingMiningPool.attach('0x544716F2a97112e8F50824F528c6651238c8FBf3');
	PRICECONTROLLER = await PriceController.attach('0xB32E590D443081d94Da62C06E057CD4C30D94084');

	USDTPToken = "0xD51e8b129834F3Ae6855dd947f25726572862135";
	ETHPToken = "0x74E1cCEEB67bF8d56D7c28D5bB0cE388DF46e509";

	// deploy nestQuary
	NESTQUARY = await NestQuery.attach('0x4b4065a5d2443CbA45a0ebd324113E3775825442');
	// deploy ntokenController
	NTOKENCONTROLLER = await NTokenController.attach('0x65D9254A562a417Ef236e430C79D7A49fdC0851b');

	PUSDMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`12. PUSDMORPOOL + "${PUSDMORPOOL.address}"`);
	PETHMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`13. PETHMORPOOL + "${PETHMORPOOL.address}"`);

	// set ptoken allow
	await PTOKENFACTORY.setPTokenOperator(PUSDMORPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PETHMORPOOL.address, "1");
	console.log(`20. PTOKENFACTORY.setPTokenOperator`);
	// set ins&mor mapping
	await PUSDMORPOOL.setInsurancePool(PUSDINSPOOL.address);
	await PETHMORPOOL.setInsurancePool(PETHINSPOOL.address);
	await PUSDINSPOOL.setMortgagePool(PUSDMORPOOL.address);
	await PETHINSPOOL.setMortgagePool(PETHMORPOOL.address);
	console.log(`21. ins&mor mapping`);
	// set pricecontroller address
	await PUSDMORPOOL.setPriceController(PRICECONTROLLER.address);
	await PETHMORPOOL.setPriceController(PRICECONTROLLER.address);
	console.log(`22. setPriceController`);
	// set mor config
	await PUSDMORPOOL.setConfig(USDTPToken, "2400000", USDTContract.address, "1");
	await PETHMORPOOL.setConfig(ETHPToken, "2400000", ETHAddress, "1");
	console.log(`23. setConfig`);

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

	console.log(`USDTContract:"${USDTContract.address}",`);
	console.log(`NESTContract:"${NESTContract.address}",`);
	console.log(`ASETContract:"${ASETContract.address}",`);
    console.log(`GovernanceContract:"${GovernanceContract.address}",`);
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

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});
