const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deploy} = require("./deployContracts-scripts.js")
const {ETH, USDT} = require("./normal-scripts.js");

async function main() {
	
	contracts = await deploy();
	const accounts = await ethers.getSigners();
	const PUSDStakingMiningPool = contracts.PUSDStakingMiningPool;
	const PETHStakingMiningPool = contracts.PETHStakingMiningPool;
	const PUSDInsPool = contracts.PUSDInsPool;
	const PETHInsPool = contracts.PETHInsPool;
	const USDTContract = contracts.USDTContract;

	await getNum(contracts);

	await USDTContract.approve(PUSDInsPool.address, USDT(99999));
	await PUSDInsPool.subscribeIns(USDT(10000));
	await contracts.ASETContract.approve(PUSDStakingMiningPool.address, ETH(10000));
	await PUSDStakingMiningPool.addToken(contracts.ASETContract.address, ETH(10000), accounts[0].address, ETH(2));
	await PUSDInsPool.approve(PUSDStakingMiningPool.address, ETH(5000));
	await PUSDStakingMiningPool.stake(ETH(5000));
	await PUSDStakingMiningPool.withdraw(ETH(1000));
	await PUSDStakingMiningPool.getReward();	
	await getNum(contracts);
}

async function getNum (contracts) {
	const accounts = await ethers.getSigners();
	const PUSDStakingMiningPool = contracts.PUSDStakingMiningPool;
	const PETHStakingMiningPool = contracts.PETHStakingMiningPool;
	const PUSDInsPool = contracts.PUSDInsPool;
	const PETHInsPool = contracts.PETHInsPool;

	_rewardsToken = await PUSDStakingMiningPool._rewardsToken();
	_stakingToken = await PUSDStakingMiningPool._stakingToken();
	_governance = await PUSDStakingMiningPool._governance();
	_lastUpdateBlock = await PUSDStakingMiningPool._lastUpdateBlock();
	_rewardPerTokenStored = await PUSDStakingMiningPool._rewardPerTokenStored();
	_rewardRate = await PUSDStakingMiningPool._rewardRate();
	_totalSupply = await PUSDStakingMiningPool._totalSupply();
	_endBlock = await PUSDStakingMiningPool._endBlock();

	userRewardPerTokenPaid = await PUSDStakingMiningPool.userRewardPerTokenPaid(accounts[0].address);
	rewards = await PUSDStakingMiningPool.rewards(accounts[0].address);
	balances = await PUSDStakingMiningPool.balances(accounts[0].address);

	console.log("====GETNUM====");
	console.log(`_rewardsToken:${_rewardsToken}`);
	console.log(`_stakingToken":${_stakingToken}`);
	console.log(`_governance":${_governance}`);
	console.log(`_lastUpdateBlock":${_lastUpdateBlock.toString()}`);
	console.log(`_rewardPerTokenStored":${_rewardPerTokenStored.toString()}`);
	console.log(`_rewardRate":${_rewardRate.toString()}`);
	console.log(`_totalSupply":${_totalSupply.toString()}`);
	console.log(`_endBlock":${_endBlock.toString()}`);
	console.log(`userRewardPerTokenPaid":${userRewardPerTokenPaid.toString()}`);
	console.log(`rewards":${rewards.toString()}`);
	console.log(`balances":${balances.toString()}`);
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});