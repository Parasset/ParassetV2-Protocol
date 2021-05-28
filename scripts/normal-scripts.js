const hre = require("hardhat");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const usdtdec = BigNumber.from(10).pow(6);
const ethdec = BigNumber.from(10).pow(18);

exports.ETH = function (amount) {
    return BigNumber.from(amount).mul(ethdec);
}

exports.USDT = function (amount) {
    return BigNumber.from(amount).mul(usdtdec);
}

exports.deployUSDT= async function () {
    const USDTContract = await ethers.getContractFactory("USDT");
    const contract = await USDTContract.deploy();
    const tx = contract.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: USDT deployed, address=${contract.address}, block=${tx.blockNumber}`);
    return contract;
}

exports.deployNEST= async function () {
    const NESTContract = await ethers.getContractFactory("NEST");
    const contract = await NESTContract.deploy();
    const tx = contract.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: NEST deployed, address=${contract.address}, block=${tx.blockNumber}`);
    return contract;
}

exports.deployASET= async function () {
    const ASETContract = await ethers.getContractFactory("ASET");
    const contract = await ASETContract.deploy();
    const tx = contract.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: ASET deployed, address=${contract.address}, block=${tx.blockNumber}`);
    return contract;
}

exports.depolyFactory = async function() {
	const Factory = await hre.ethers.getContractFactory("PTokenFactory");
	const contract = await Factory.deploy();
	const tx = contract.deployTransaction;
	await tx.wait(1);
	console.log(`>>> [DPLY]: PTokenFactory deployed, address=${contract.address}, block=${tx.blockNumber}`);
	return contract;
}

exports.createPtoken = async function (factory, name) {
	const Factory = await ethers.getContractAt("PTokenFactory", factory);
    const tx = await Factory.createPtoken(name);
    await tx.wait(1);
    console.log(`>>> [CREATE SUCCESS]`);
}

exports.getPTokenAddress = async function (factory, index) {
	const Factory = await ethers.getContractAt("PTokenFactory", factory);
    const address = await Factory.getPTokenAddress(index);
    console.log(`>>> pTokenAddress=${address}`);
    return address;
}

exports.deployNestQuery = async function () {
	const NestQueryContract = await ethers.getContractFactory("NestQuery");
    const contract = await NestQueryContract.deploy();
    const tx = contract.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: NestQuery deployed, address=${contract.address}, block=${tx.blockNumber}`);
    return contract;
}

exports.deployLPStakingMiningPool = async function (rewardsToken, stakingToken) {
	const LPStakingMiningPool = await ethers.getContractFactory("LPStakingMiningPool");
    const contract = await LPStakingMiningPool.deploy(rewardsToken, stakingToken);
    const tx = contract.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: LPStakingMiningPool deployed, address=${contract.address}, block=${tx.blockNumber}`);
    return contract;
}

exports.deployNTokenController= async function () {
    const NTokenController = await ethers.getContractFactory("NTokenController");
    const controller = await NTokenController.deploy();
    const tx = controller.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: deployNTokenController deployed, address=${controller.address}, block=${tx.blockNumber}`);
    return controller;
}

exports.setNTokenMapping = async function(controller, priceContract, token, nToken) {
    const NTokenController = await ethers.getContractAt("NTokenController", controller);
    const tx1 = await NTokenController.setNTokenMapping(token, nToken);
    await tx1.wait(1);
    const price = await ethers.getContractAt("NestQuery", priceContract);
    const tx2 = await price.setNTokenMapping(token, nToken);
    await tx2.wait(1);
    console.log(`>>> [SetNTokenMapping SUCCESS]`);
}

exports.setAvg = async function (quaryAddress, token, avg) {
	const NestQueryContract = await ethers.getContractAt("NestQuery", quaryAddress);
	const set = await NestQueryContract.setAvg(token, avg);
	await set.wait(1);
	console.log(`>>> [SETPRICE]: ${token} => ${avg}`);
}

exports.deployMortgagePool = async function (factory) {
	const MortgagePool = await hre.ethers.getContractFactory("MortgagePool");
    const pool = await MortgagePool.deploy(factory);
    await pool.deployed();
    const tx = pool.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: MortgagePool deployed, address=${pool.address}, block=${tx.blockNumber}`);
    return pool;
}

exports.deployInsurancePool = async function (factory, name, sysbol) {
	const InsurancePool = await hre.ethers.getContractFactory("InsurancePool");
    const pool = await InsurancePool.deploy(factory, name, sysbol);
    await pool.deployed();
    const tx = pool.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: InsurancePool deployed, address=${pool.address}, block=${tx.blockNumber}`);
    return pool;
}

exports.deployPriceController= async function (priceContract, ntokenController) {
    const PriceControllerContract = await ethers.getContractFactory("PriceController");
    const PriceController = await PriceControllerContract.deploy(priceContract,ntokenController);
    const tx = PriceController.deployTransaction;
    await tx.wait(1);
    console.log(`>>> [DPLY]: PriceController deployed, address=${PriceController.address}, block=${tx.blockNumber}`);
    return PriceController;
}

exports.setPTokenOperator = async function(factory, add, allow) {
	const fac = await ethers.getContractAt("PTokenFactory", factory);
    const Operator = await fac.setPTokenOperator(add, allow);
    await Operator.wait(1);
    console.log(`>>> [SetPTokenOperator SUCCESS]`);
}

exports.setInsurancePool = async function (mortgagePool, add) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const set = await pool.setInsurancePool(add);
    await set.wait(1);
    console.log(`>>> [setInsurancePool SUCCESS]`);
}

exports.setMortgagePool = async function (insurancePool, add) {
	const pool = await ethers.getContractAt("InsurancePool", insurancePool);
    const set = await pool.setMortgagePool(add);
    await set.wait(1);
    console.log(`>>> [setMortgagePool SUCCESS]`);
}

exports.setFlag = async function(mortgagePool, num) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const setFlag = await pool.setFlag(num);
    await setFlag.wait(1);
    console.log(`>>> [setFlag SUCCESS]`);
}

exports.setFlag2 = async function(insurancePool, num) {
	const pool = await ethers.getContractAt("InsurancePool", insurancePool);
    const setFlag = await pool.setFlag(num);
    await setFlag.wait(1);
    console.log(`>>> [setFlag SUCCESS]`);
}

exports.setETHINS = async function(insurancePool) {
    const pool = await ethers.getContractAt("InsurancePool", insurancePool);
    const setETHIns = await pool.setETHIns(true);
    await setETHIns.wait(1);
    console.log(`>>> [setETHIns SUCCESS]`);
}

exports.allow = async function (mortgagePool, MToken) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const allow = await pool.setMortgageAllow(MToken, "1");
    await allow.wait(1);
    console.log(`>>> [ALLOW SUCCESS]`);
}

exports.setMaxRate = async function (mortgagePool, MToken, rate) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const maxRate = await pool.setMaxRate(MToken, rate);
    await maxRate.wait(1);
    console.log(`>>> [setMaxRate SUCCESS]`);
}

exports.setK = async function (mortgagePool, MToken, num) {
    const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const line = await pool.setK(MToken, num);
    await line.wait(1);
    console.log(`>>> [setK SUCCESS]`);
}

exports.setR0 = async function (mortgagePool, MToken, num) {
    const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const line = await pool.setR0(MToken, num);
    await line.wait(1);
    console.log(`>>> [setR0 SUCCESS]`);
}

exports.setInfo = async function (mortgagePool, token, pToken) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
	const setInfo = await pool.setInfo(token, pToken);
	await setInfo.wait(1);
    console.log(`>>> [setInfo SUCCESS]`);
}

exports.setPriceController = async function (mortgagePool, priceController) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const setPriceController = await pool.setPriceController(priceController);
    await setPriceController.wait(1);
    console.log(`>>> [setPriceController SUCCESS]`);
}

exports.getLedger = async function (mortgagePool, MToken, owner) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const ledger = await pool.getLedger(MToken, owner);
    console.log(`>>>> 抵押资产数量:${ledger[0].toString()}`);
    console.log(`>>>> 债务数量:${ledger[1].toString()}`);
    console.log(`>>>> 最近操作区块号:${ledger[2].toString()}`);
    console.log(`>>>> 抵押率:${ledger[3].toString()}`);
    console.log(`>>>> 是否创建:${ledger[4].toString()}`);
    return [ledger[0], ledger[1], ledger[2], ledger[3], ledger[4]];
}

exports.getInfoRealTime = async function (mortgagePool, MToken, tokenPrice, uTokenPrice, maxRateNum, owner) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const info = await pool.getInfoRealTime(MToken, tokenPrice, uTokenPrice, maxRateNum, owner);
    console.log("~~~实时数据~~~")
    console.log(`~~~稳定费:${info[0].toString()}`);
    console.log(`~~~抵押率:${info[1].toString()}`);
    console.log(`~~~最大可减少抵押资产数量:${info[2].toString()}`);
    console.log(`~~~最大可新增铸币数量:${info[3].toString()}`);
    return [info[0], info[1], info[2], info[3]];
}