const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deploy} = require("./deployContracts-scripts.js")
const {ETHdec, USDTdec} = require("./normal-scripts.js");

async function main() {
	
	contracts = await deploy();
	const accounts = await ethers.getSigners();
	const StakingMiningPool = contracts.StakingMiningPool;
	const PUSDInsPool = contracts.PUSDInsPool;
	const PETHInsPool = contracts.PETHInsPool;
	const USDTContract = contracts.USDTContract;
	console.log(PUSDInsPool.address);

	await USDTContract.approve(PUSDInsPool.address, USDTdec(99999));
	await PUSDInsPool.subscribeIns(USDTdec(10000));
	await contracts.ASETContract.approve(StakingMiningPool.address, ETHdec(10000));
	await StakingMiningPool.addToken(ETHdec(10000), accounts[0].address, ETHdec(2), PUSDInsPool.address);
	await PUSDInsPool.approve(StakingMiningPool.address, ETHdec(5000));
	logAccountInfo(StakingMiningPool, PUSDInsPool.address, accounts[0].address);
	await StakingMiningPool.stake(ETHdec(5000), PUSDInsPool.address);
	logAccountInfo(StakingMiningPool, PUSDInsPool.address, accounts[0].address);
	await StakingMiningPool.withdraw(ETHdec(1000), PUSDInsPool.address);
	logAccountInfo(StakingMiningPool, PUSDInsPool.address, accounts[0].address);
	await StakingMiningPool.getReward(PUSDInsPool.address);	
	logAccountInfo(StakingMiningPool, PUSDInsPool.address, accounts[0].address);

}

async function logAccountInfo(stakingMiningPool, stakingToken, accountAdd) {
	const accountInfo = await stakingMiningPool.getAccountInfo(stakingToken, accountAdd);
	console.log(`balance:"${accountInfo[0].toString()}",`);
	console.log(`userRewardPerTokenPaid:"${accountInfo[1].toString()}",`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});