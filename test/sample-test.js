const { expect } = require("chai");
const {deployUSDT} = require("../scripts/normal-scripts.js");

// describe("Greeter", function() {
//   it("Should return the new greeting once it's changed", async function() {
//     const Greeter = await ethers.getContractFactory("Greeter");
//     const greeter = await Greeter.deploy("Hello, world!");
    
//     await greeter.deployed();
//     expect(await greeter.greet()).to.equal("Hello, world!");

//     await greeter.setGreeting("Hola, mundo!");
//     expect(await greeter.greet()).to.equal("Hola, mundo!");
//   });
// });

describe("USDT", function() {
  it("Should return the new greeting once it's changed", async function() {
    USDT = await deployUSDT();
  });
});
