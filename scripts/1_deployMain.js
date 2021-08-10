const { ethers, upgrades } = require("hardhat");

const {ETHdec,USDTdec} = require("./normal-scripts.js")

exports.deploy = async function () {
    const ETHAddress = "0x0000000000000000000000000000000000000000";
    const USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";
    const NEST = "0x04abEdA201850aC0124161F037Efd70c74ddC74C";
    const NestQuery = "0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A";
    const NTokenController = "0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62";
    const PETH = "0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD";
    const PUSD = "0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0";

    const oldMor = "0xd8E5EfE8DDbe78C8B08bdd70A6dc668F54a6C01c";
    const oldIns = "0xc80Ebc9eC1BB8DBC8e93D4C904372dD19786dc9C";

	const ASET = await ethers.getContractFactory("ASET");
	const ParassetGovernance = await ethers.getContractFactory("ParassetGovernance");
	const PTokenFactory = await hre.ethers.getContractFactory("PTokenFactory");
	const MortgagePool = await ethers.getContractFactory("MortgagePool");
	const InsurancePool = await hre.ethers.getContractFactory("InsurancePool");
	const LPStakingMiningPool = await ethers.getContractFactory("LPStakingMiningPool");
	const PriceController = await ethers.getContractFactory("PriceController");

    // deploy ASET
	const ASETContract = await ASET.deploy();
	console.log(`1. ASETContract + "${ASETContract.address}"`);
	// deploy Governance
	const GovernanceContract = await ParassetGovernance.deploy();
	console.log(`2. ParassetGovernance + "${GovernanceContract.address}"`);
	// deploy Factory
	const PTOKENFACTORY = await upgrades.deployProxy(PTokenFactory, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`3. PTOKENFACTORY + "${PTOKENFACTORY.address}"`);
    // deploy mor usd
    const PUSDMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`4. PUSDMORPOOL + "${PUSDMORPOOL.address}"`);
    // deploy mor eth
	const PETHMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`5. PETHMORPOOL + "${PETHMORPOOL.address}"`);
    // deploy ins usd
	const PUSDINSPOOL = await upgrades.deployProxy(InsurancePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`6. PUSDINSPOOL + "${PUSDINSPOOL.address}"`);
    // deploy ins eth
	const PETHINSPOOL = await upgrades.deployProxy(InsurancePool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`7. PETHINSPOOL + "${PETHINSPOOL.address}"`);
    // deploy stake
	const LPSTAKING = await upgrades.deployProxy(LPStakingMiningPool, [GovernanceContract.address], { initializer: 'initialize' });
	console.log(`8. LPSTAKING + "${LPSTAKING.address}"`);
    // deploy price
	const PRICECONTROLLER = await PriceController.deploy(NestQuery, NTokenController);
	console.log(`9. PRICECONTROLLER + "${PRICECONTROLLER.address}"`);

    // ------------------

    // setting
    // add PToken
    await PTOKENFACTORY.addPTokenList(PUSD);
    await PTOKENFACTORY.addPTokenList(PETH);
    console.log(`10. Add PToken`);
    // set ptoken allow
	await PTOKENFACTORY.setPTokenOperator(PUSDMORPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PETHMORPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PUSDINSPOOL.address, "1");
	await PTOKENFACTORY.setPTokenOperator(PETHINSPOOL.address, "1");
    await PTOKENFACTORY.setPTokenOperator(oldMor, "1");
	await PTOKENFACTORY.setPTokenOperator(oldIns, "1");
    console.log(`11. PTOKENFACTORY.setPTokenOperator`);
    // set mor-ins address
	await PUSDMORPOOL.setInsurancePool(PUSDINSPOOL.address);
	await PETHMORPOOL.setInsurancePool(PETHINSPOOL.address);
    console.log(`12. set mor-ins address`);
    // set mor-price address
	await PUSDMORPOOL.setPriceController(PRICECONTROLLER.address);
	await PETHMORPOOL.setPriceController(PRICECONTROLLER.address);
    console.log(`13. set mor-price address`);
    // set mor-config
	await PUSDMORPOOL.setConfig(PUSD, "2400000", USDT, "0");
	await PETHMORPOOL.setConfig(PETH, "2400000", ETHAddress, "0");
    console.log(`14. set mor-config`);
    // set mor-token info
	await PUSDMORPOOL.setMortgageAllow(ETHAddress, true);
	await PUSDMORPOOL.setMaxRate(ETHAddress, "70000");
	await PUSDMORPOOL.setK(ETHAddress, "120000");
	await PUSDMORPOOL.setR0(ETHAddress, "2000");
    await PUSDMORPOOL.setLiquidateRate(ETHAddress, "90000");
	await PUSDMORPOOL.setMortgageAllow(NEST, true);
	await PUSDMORPOOL.setMaxRate(NEST, "40000");
	await PUSDMORPOOL.setK(NEST, "133000");
	await PUSDMORPOOL.setR0(NEST, "2000");
    await PUSDMORPOOL.setLiquidateRate(NEST, "90000");
	console.log(`15. set mor-token info, PUSD`);
	await PETHMORPOOL.setMortgageAllow(NEST, true);
	await PETHMORPOOL.setMaxRate(NEST, "40000");
	await PETHMORPOOL.setK(NEST, "133000");
	await PETHMORPOOL.setR0(NEST, "2000");
    await PETHMORPOOL.setLiquidateRate(NEST, "90000");
	console.log(`16. set mor-token info, PETH`);
    // set ins-mor address
    await PUSDINSPOOL.setMortgagePool(PUSDMORPOOL.address);
	await PETHINSPOOL.setMortgagePool(PETHMORPOOL.address);
    console.log(`17. set ins-mor address`);
    // set ins-info
	await PETHINSPOOL.setTokenInfo("LP-ETH", "LP-ETH");
	await PUSDINSPOOL.setTokenInfo("LP-USD", "LP-USD");
	await PETHINSPOOL.setInfo(ETHAddress, PETH);
	await PUSDINSPOOL.setInfo(USDT, PUSD);
    console.log(`18. set ins-info`);
    // set ins-stake address
	await PUSDINSPOOL.setLPStakingMiningPool(LPSTAKING.address);
	await PETHINSPOOL.setLPStakingMiningPool(LPSTAKING.address);
    console.log(`19. set ins-stake address`);
    // set stake-reward token
	await LPSTAKING.setRewardsToken(ASETContract.address);
	console.log(`20. set stake-reward token`);
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