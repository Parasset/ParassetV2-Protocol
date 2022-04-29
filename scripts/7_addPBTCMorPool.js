const { ethers, upgrades } = require("hardhat")
const { ETHdec, USDTdec } = require("./normal-scripts.js")

async function main() {
    const ETHAddress = "0x0000000000000000000000000000000000000000";
    const NEST = "0x04abEdA201850aC0124161F037Efd70c74ddC74C";
    const HBTC = '0x0316EB71485b0Ab14103307bf65a021042c6d380';
    const PBTC = '0x102E6BBb1eBfe2305Ee6B9E9fd5547d0d39CE3B4';
    const PTokenFactoryAdd = '0xa6F7E15e38a5ba0435E5af06326108204cD175DA';
    const GovernanceAdd = '0x175d282Bc8249a3b92682365118f693380cA31F4';
    const PBTCInsPoolAdd = '0x1dc9a3856e04ed012F27e021fA7052F62FBB2832';
    const nest3Add = '0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A';
    const nest4Add = '0xE544cF993C7d477C7ef8E91D28aCA250D135aa03';

    const PTokenFactory = await hre.ethers.getContractFactory("PTokenFactory");
    const InsurancePool = await hre.ethers.getContractFactory("InsurancePool");
    const MortgagePool = await hre.ethers.getContractFactory("MortgagePool");
    const PriceController3 = await hre.ethers.getContractFactory("PriceController3");

    const PTOKENFACTORY = await PTokenFactory.attach(PTokenFactoryAdd);
    const PBTCINSPOOL = await InsurancePool.attach(PBTCInsPoolAdd);

    // creat PriceController
    const PriceController = await PriceController3.deploy(nest4Add, nest3Add);
    console.log(`PriceController + "${PriceController.address}"`);
    // create morPool
    const PBTCMORPOOL = await upgrades.deployProxy(MortgagePool, [GovernanceAdd], { initializer: 'initialize' });
    console.log(`PBTCMORPOOL + "${PBTCMORPOOL.address}"`);
    // set ptoken allow
    await PTOKENFACTORY.setPTokenOperator(PBTCMORPOOL.address, "1");
    console.log(`set ptoken allow`);
    // set mor-ins address
    await PBTCMORPOOL.setInsurancePool(PBTCInsPoolAdd);
    console.log(`set mor-ins address`);
    // set mor-price address
    await PBTCMORPOOL.setPriceController(PriceController.address);
    console.log(`set mor-price address`);
    // set mor-config
    await PBTCMORPOOL.setConfig(PBTC, "2400000", HBTC, "1");
    console.log(`set mor-config`);
    // set mor-token info
    await PBTCMORPOOL.setMortgageAllow(ETHAddress, true);
    await PBTCMORPOOL.setMaxRate(ETHAddress, "70000");
    await PBTCMORPOOL.setK(ETHAddress, "120000");
    await PBTCMORPOOL.setR0(ETHAddress, "2000");
    await PBTCMORPOOL.setLiquidateRate(ETHAddress, "90000");
    await PBTCMORPOOL.setMortgageAllow(NEST, true);
    await PBTCMORPOOL.setMaxRate(NEST, "40000");
    await PBTCMORPOOL.setK(NEST, "133000");
    await PBTCMORPOOL.setR0(NEST, "2000");
    await PBTCMORPOOL.setLiquidateRate(NEST, "90000");
    console.log(`set mor-token info`);
    // set ins-mor address
    await PBTCINSPOOL.setMortgagePool(PBTCMORPOOL.address);
    console.log(`set ins-mor address`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });