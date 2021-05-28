const hre = require("hardhat");
const { ethers } = require("hardhat");

const {depolyFactory,createPtoken,getPTokenAddress} = require("./normal-scripts.js")

async function main() {
	const accounts = await ethers.getSigners();
	// deploy USDT
	PTOKENFACTORY = await depolyFactory();
	// create PUSD
	await createPtoken(PTOKENFACTORY.address, "USD");
	// create PETH
	await createPtoken(PTOKENFACTORY.address, "ETH");

	const USDTPToken = await getPTokenAddress(PTOKENFACTORY.address, "0");
	const ETHPToken = await getPTokenAddress(PTOKENFACTORY.address, "1");


	console.log(`PTokenFactory:"${PTOKENFACTORY.address}",`);
	console.log(`PUSD:"${USDTPToken}",`);
	console.log(`PETH:"${ETHPToken}",`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});