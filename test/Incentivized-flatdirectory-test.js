const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const {writeChunkTest,writeTest,removeTest,removeChunkTest,readTest} = require("./shared/utils");

describe("IncentivizedFlatKV Test", function () {
  let OPFlatDirectory;
  let owner;
  let operator;
  let user;
  beforeEach(async () => {
    [owner,operator,user] = await ethers.getSigners();
    factory = await ethers.getContractFactory("IncentivizedFlatKV");
    OPFlatDirectory = await factory.deploy(220);
    await OPFlatDirectory.deployed();
  });

  it("permission transfer test", async function () {
    expect(await OPFlatDirectory.owner()).to.eq(owner.address);
    await OPFlatDirectory.changeOperator(operator.address); 
    expect(await OPFlatDirectory.operator()).to.eq(operator.address);

    await expect(OPFlatDirectory.connect(operator).changeOwner(operator.address)).to.be.reverted
    await expect(OPFlatDirectory.connect(user.address).changeOperator(operator.address)).to.be.reverted

    await OPFlatDirectory.connect(operator).changeOperator(user.address)
    expect(await OPFlatDirectory.operator()).to.eq(user.address)
    
    await expect(OPFlatDirectory.connect(operator.address).changeOwner(user.address)).to.be.reverted
  });

  it("permission  test", async function () {
    expect(await OPFlatDirectory.owner()).to.eq(owner.address);
    await OPFlatDirectory.changeOperator(operator.address); 
    expect(await OPFlatDirectory.operator()).to.eq(operator.address);
    
    // expect write revert
    await expect(writeTest(OPFlatDirectory.connect(user), "0x01", 100, 1)).to.be.reverted;
    await expect(writeChunkTest(OPFlatDirectory.connect(user), "0x01", 0, 1000, 1)).to.be.reverted;

    // expect write succeed
    await writeTest(OPFlatDirectory.connect(owner), "0x01", 100, 1)
    await writeChunkTest(OPFlatDirectory.connect(owner), "0x01", 1, 1000, 1)

    // expect remove revert
    await expect(removeTest(OPFlatDirectory.connect(user), "0x01")).to.be.reverted;
    await expect(removeChunkTest(OPFlatDirectory.connect(user), "0x01",0)).to.be.reverted;

    // expect remove succeed
    await removeChunkTest(OPFlatDirectory.connect(owner), "0x01",1)
    await removeTest(OPFlatDirectory.connect(owner), "0x01")
    await readTest(OPFlatDirectory.connect(user), "0x01",0,0,0,0,0,0)

  });

});
