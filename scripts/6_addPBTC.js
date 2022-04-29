const { ethers, upgrades } = require("hardhat")
const {ETHdec,USDTdec} = require("./normal-scripts.js")

async function main() {
    const HBTC = '0x0316EB71485b0Ab14103307bf65a021042c6d380';
    const PBTC = '0x102E6BBb1eBfe2305Ee6B9E9fd5547d0d39CE3B4';
    const PTokenFactoryAdd = '0xa6F7E15e38a5ba0435E5af06326108204cD175DA';
    const GovernanceAdd = '0x175d282Bc8249a3b92682365118f693380cA31F4';
    const LPStakingAdd = '0xbA01258Eb8e133EACE55F5f6ec76907ADdf7797f'

    const PTokenFactory = await hre.ethers.getContractFactory("PTokenFactory");
	const InsurancePool = await hre.ethers.getContractFactory("InsurancePool");

    const PTOKENFACTORY = await PTokenFactory.attach(PTokenFactoryAdd);
    // create insPool
    const PBTCINSPOOL = await upgrades.deployProxy(InsurancePool, [GovernanceAdd], { initializer: 'initialize' });
	console.log(`PBTCINSPOOL + "${PBTCINSPOOL.address}"`);
    
    await PTOKENFACTORY.setPTokenOperator(PBTCINSPOOL.address, "1");
    console.log(`setPTokenOperator`);
    // set ins-info
	await PBTCINSPOOL.setTokenInfo("LP-BTC", "LP-BTC");
	await PBTCINSPOOL.setInfo(HBTC, PBTC);
    console.log(`set ins-info`);
    // set ins-stake address
	await PBTCINSPOOL.setLPStakingMiningPool(LPStakingAdd);
    console.log(`set ins-stake address`);
    // set ins-latestTime
	await PBTCINSPOOL.setLatestTime("1646582400");
    console.log(`set ins-latestTime`);
    // set flag
    await PBTCINSPOOL.setFlag('1');
    console.log(`set flag`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});