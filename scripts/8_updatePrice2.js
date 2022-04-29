const { ethers, upgrades } = require("hardhat")
const { ETHdec, USDTdec } = require("./normal-scripts.js")

async function main() {
    const PBTCMorPoolAdd = '0x1738123F73654A18CB9D5c2C1e6B972E84EA1360';
    const PUSDMorPoolAdd = '0xE6eda6C6E149A887c516066CEdfa8D7fa429Cd1b';
    const PETHMorPoolAdd = '0x95e5592C76Dd8De5301e65fda3E4D78e1bc4e018';
    const nest4Add = '0xc08E6A853241B9a08225EECf93F3b279FA7A1bE7';

    const MortgagePool = await hre.ethers.getContractFactory("MortgagePool");
    const PriceController2 = await hre.ethers.getContractFactory("PriceController2");

    const PBTCMORPOOL = await MortgagePool.attach(PBTCMorPoolAdd);
    const PUSDMORPOOL = await MortgagePool.attach(PUSDMorPoolAdd);
    const PETHMORPOOL = await MortgagePool.attach(PETHMorPoolAdd);

    // creat PriceController
    const PriceController = await PriceController2.deploy(nest4Add);
    console.log(`PriceController + "${PriceController.address}"`);
    // set mor-price address
    await PBTCMORPOOL.setPriceController(PriceController.address);
    console.log(`set mor-price address`);
    // set mor-price address
    await PUSDMORPOOL.setPriceController(PriceController.address);
    console.log(`set mor-price address`);
    // set mor-price address
    await PETHMORPOOL.setPriceController(PriceController.address);
    console.log(`set mor-price address`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });