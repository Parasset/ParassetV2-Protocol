const { ethers } = require("hardhat");
const contracts = require("./contracts.js");
const {ETHdec, USDTdec} = require("./normal-scripts.js");

async function main() {

	const accounts = await ethers.getSigners();
	const ASET = await ethers.getContractFactory("ASET");
	const InsurancePool = await ethers.getContractFactory("InsurancePool");
	const LPStakingMiningPool = await ethers.getContractFactory("LPStakingMiningPool");

	const ASETToken = await ASET.attach(contracts.ASETContract);
	const PUSDIns = await InsurancePool.attach(contracts.PUSDInsPool);
	const StakingPool = await LPStakingMiningPool.attach(contracts.StakingMiningPool);

	// await PUSDIns.approve(StakingPool.address, ETHdec("999999999"));

	// await StakingPool.stake(ETHdec("5"), PUSDIns.address);

	// await ASETToken.approve(StakingPool.address, ETHdec("99999999"));
	// await StakingPool.addToken(ETHdec(10), accounts[0].address, ETHdec(1), PUSDIns.address);

	await StakingPool.getReward(PUSDIns.address);

	await StakingPool.withdraw(ETHdec("3"),PUSDIns.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});