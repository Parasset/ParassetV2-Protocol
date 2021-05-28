const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deployNestQuery,deployNTokenController,setNTokenMapping,setAvg,ETH,USDT} = require("./normal-scripts.js")
const contracts = require("./contracts.js");

async function main() {
	const accounts = await ethers.getSigners();
	// deploy nestQuary
	NESTQUARY = await deployNestQuery();
	// deploy ntokenController
	NTOKENCONTROLLER = await deployNTokenController();

	await setNTokenMapping(NTOKENCONTROLLER.address, NESTQUARY.address, contracts.USDTContract, contracts.NESTContract);
	await setAvg(NESTQUARY.address,contracts.USDTContract, USDT("2"));
	await setAvg(NESTQUARY.address,contracts.NESTContract, ETH("3"));

	console.log(`NestQuery:"${NESTQUARY.address}",`);
	console.log(`NTokenController:"${NTOKENCONTROLLER.address}",`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});