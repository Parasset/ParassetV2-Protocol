const hre = require("hardhat");
const { ethers } = require("hardhat");

const {deployUSDT,deployNEST,deployASET} = require("./normal-scripts.js")

async function main() {
	const accounts = await ethers.getSigners();
	// deploy USDT
	USDTContract = await deployUSDT();
	// deploy NEST
	NESTContract = await deployNEST();
	// deploy ASET
	ASETContract = await deployASET();

	console.log(`USDTContract:"${USDTContract.address}",`);
	console.log(`NESTContract:"${NESTContract.address}",`);
	console.log(`ASETContract:"${ASETContract.address}",`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});