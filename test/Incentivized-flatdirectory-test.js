const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const {writeChunkTest,writeTest,removeTest,removeChunkTest,readTest} = require("./shared/utils");

let ETH = BigNumber.from(10).pow(18)
let ChunkSize = BigNumber.from(1024)
let CodeStakingPerChunk = BigNumber.from(10).pow(BigNumber.from(18))

describe("IncentivizedFlatKV Test", function () {
  let OPFlatDirectory;
  let owner;
  let operator;
  let user;
  let sendedEth;
  beforeEach(async () => {
    [owner,operator,user] = await ethers.getSigners();
    factory = await ethers.getContractFactory("IncentivizedFlatDirectory");
    sendedEth = BigNumber.from(10).pow(BigNumber.from(19));
    OPFlatDirectory = await factory.deploy(220,ChunkSize,CodeStakingPerChunk,{value: sendedEth});
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

  it("operator with different permissions test", async function () {
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

  it("verify contract balance after write operation",async function(){
    let totalTokenConsumed = BigNumber.from(0);

    // verify FaatDirectory contract balance
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
    // set operator
    await OPFlatDirectory.changeOperator(operator.address)

    // need stake one eth 
    let data0 = Array.from({ length: ChunkSize }, () =>
      Math.floor(Math.random() * 256)
    );
    await OPFlatDirectory.connect(operator).write("0x01",data0)
    expect(await  ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth.sub(ETH))
    totalTokenConsumed = totalTokenConsumed.add(ETH);

    // need stake two eth 
    let data1 = Array.from({ length: ChunkSize * 2}, () =>
      Math.floor(Math.random() * 256)
    );
    await OPFlatDirectory.connect(operator).write("0x02",data1)
    expect(await  ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth.sub(ETH.mul(2)).sub(totalTokenConsumed))
    totalTokenConsumed = totalTokenConsumed.add(ETH.mul(2))

    // do not need stake 
    let storageSlotCodeLen = await OPFlatDirectory.storageSlotCodeLength();
    let v = await OPFlatDirectory.calculateValueForData(ChunkSize.sub(storageSlotCodeLen))
    console.log("need value",v.toString())
    expect(v).to.eq(BigNumber.from(0))

    let data2 = Array.from({ length: ChunkSize.sub(storageSlotCodeLen) }, () =>
      Math.floor(Math.random() * 256)
    );
    await OPFlatDirectory.connect(operator).write("0x03",data2)
    expect(await  ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth.sub(totalTokenConsumed))
  })

  it("write and remove test",async function(){
    let totalTokenConsumed = BigNumber.from(0);

    // verify FaatDirectory contract balance
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
    // set operator
    await OPFlatDirectory.changeOperator(operator.address)

    // need stake one eth 
    let data0 = Array.from({ length: ChunkSize }, () =>
      Math.floor(Math.random() * 256)
    );
    await OPFlatDirectory.connect(operator).write("0x01",data0)
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth.sub(ETH))
    totalTokenConsumed = totalTokenConsumed.add(ETH);

    await OPFlatDirectory.connect(operator).remove("0x01")
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
  })

  it("writeChunk and removeChunk test",async function(){
    let totalTokenConsumed = BigNumber.from(0);

    // verify FaatDirectory contract balance
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
    // set operator
    await OPFlatDirectory.changeOperator(operator.address)

    // need stake one eth 
    let data0 = Array.from({ length: ChunkSize }, () =>
      Math.floor(Math.random() * 256)
    );
    await OPFlatDirectory.connect(operator).writeChunk("0x01", 0, data0)
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth.sub(ETH))
    totalTokenConsumed = totalTokenConsumed.add(ETH);

    await OPFlatDirectory.connect(operator).removeChunk( "0x01", 0)
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
  })

  it("writeChunk and removeChunk test",async function(){
    let totalTokenConsumed = BigNumber.from(0);

    // verify FaatDirectory contract balance
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
    // set operator
    await OPFlatDirectory.changeOperator(operator.address)

    // need stake one eth 
    let data0 = Array.from({ length: ChunkSize }, () =>
      Math.floor(Math.random() * 256)
    );
    await OPFlatDirectory.connect(operator).writeChunk("0x01", 0, data0)
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth.sub(ETH))
    totalTokenConsumed = totalTokenConsumed.add(ETH);

    await OPFlatDirectory.connect(operator).removeChunk( "0x01", 0)
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
  })

  it("refund with different permissions test",async function(){
    // verify FaatDirectory contract balance
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
    // set operator
    await OPFlatDirectory.changeOperator(operator.address)

    // refund fail
    await expect(OPFlatDirectory.connect(operator).refund()).to.be.reverted

    // refund succeed
    await OPFlatDirectory.connect(owner).refund()
  })


  it("destruct with different permissions test",async function(){
    // verify FaatDirectory contract balance
    expect(await ethers.provider.getBalance(OPFlatDirectory.address)).to.eq(sendedEth)
    // set operator
    await OPFlatDirectory.changeOperator(operator.address)

    // refund fail
    await expect(OPFlatDirectory.connect(operator).destruct()).to.be.reverted

    // refund succeed
    await OPFlatDirectory.connect(owner).destruct()
  })



});
