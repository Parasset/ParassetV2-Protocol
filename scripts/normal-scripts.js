const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");
const { BigNumber } = require("ethers");

const usdtdec = BigNumber.from(10).pow(6);
const ethdec = BigNumber.from(10).pow(18);

exports.ETHdec = function (amount) {
    return BigNumber.from(amount).mul(ethdec);
}

exports.USDTdec = function (amount) {
    return BigNumber.from(amount).mul(usdtdec);
}


exports.getLedger = async function (mortgagePool, MToken, owner) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const ledger = await pool.getLedger(MToken, owner);
    console.log(`>>>> 抵押资产数量:${ledger[0].toString()}`);
    console.log(`>>>> 债务数量:${ledger[1].toString()}`);
    console.log(`>>>> 最近操作区块号:${ledger[2].toString()}`);
    console.log(`>>>> 抵押率:${ledger[3].toString()}`);
    console.log(`>>>> 是否创建:${ledger[4].toString()}`);
    return [ledger[0], ledger[1], ledger[2], ledger[3], ledger[4]];
}

exports.getInfoRealTime = async function (mortgagePool, MToken, tokenPrice, uTokenPrice, maxRateNum, owner) {
	const pool = await ethers.getContractAt("MortgagePool", mortgagePool);
    const info = await pool.getInfoRealTime(MToken, tokenPrice, uTokenPrice, maxRateNum, owner);
    console.log("~~~实时数据~~~")
    console.log(`~~~稳定费:${info[0].toString()}`);
    console.log(`~~~抵押率:${info[1].toString()}`);
    console.log(`~~~最大可减少抵押资产数量:${info[2].toString()}`);
    console.log(`~~~最大可新增铸币数量:${info[3].toString()}`);
    return [info[0], info[1], info[2], info[3]];
}