const { ethers, upgrades } = require("hardhat")
const {ETHdec,USDTdec} = require("./normal-scripts.js")

async function main() {
    const HBTC = '0x8eF7Eec35b064af3b38790Cd0Afd3CF2FF5203A4';
    const PBTC = '0x4a3d5e6338a15a778ec342ee007037911a4ddf52';
    const PTokenFactoryAdd = '0xdae16494Bf95085Efac4aaF238cC3d6eFd23C7A5';
    const GovernanceAdd = '0xFfA0a9E299419acCf0b467017409BB3F6Bc25dEF';
    const LPStakingAdd = '0x544716F2a97112e8F50824F528c6651238c8FBf3'

    const PTokenFactory = await hre.ethers.getContractFactory("PTokenFactory");
	const InsurancePool = await hre.ethers.getContractFactory("InsurancePool");

    const PTOKENFACTORY = await PTokenFactory.attach(PTokenFactoryAdd);
    // create insPool
    const PBTCINSPOOL = await upgrades.deployProxy(InsurancePool, [GovernanceAdd], { initializer: 'initialize' });
	console.log(`PBTCINSPOOL + "${PBTCINSPOOL.address}"`);
    
    await PTOKENFACTORY.setPTokenOperator(PBTCINSPOOL.address, "1");
    // set ins-info
	await PBTCINSPOOL.setTokenInfo("LP-BTC", "LP-BTC");
	await PBTCINSPOOL.setInfo(HBTC, PBTC);
    // set ins-stake address
	await PBTCINSPOOL.setLPStakingMiningPool(LPStakingAdd);
    // set ins-latestTime
	await PBTCINSPOOL.setLatestTime("1645510930");
    // set flag
    await PBTCINSPOOL.setFlag('1');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});