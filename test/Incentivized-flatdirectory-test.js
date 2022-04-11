const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers, web3 } = require("hardhat");
const { writeChunkTest, writeTest, removeTest, removeChunkTest, readTest } = require("./shared/utils");

let ETH = BigNumber.from(10).pow(18);
let ChunkSize = BigNumber.from(1024).mul(BigNumber.from(24));
let CodeStakingPerChunk = BigNumber.from(10).pow(BigNumber.from(18));
let overrideData = { maxPriorityFeePerGas: BigNumber.from(16 * 10 ** 9), maxFeePerGas: BigNumber.from(31 * 10 ** 9) };

describe("IncentivizedFlatDirectory Test", function () {
  let fd;
  let owner;
  let operator;
  let user;
  let sendedEth;

  beforeEach(async () => {
    [owner, operator, user,] = await ethers.getSigners();
    console.log(owner.address ,operator.address , user.address)
    factory = await ethers.getContractFactory("IncentivizedFlatDirectory");
    sendedEth = BigNumber.from(4).mul(CodeStakingPerChunk);
    let _nonce = await ethers.provider.getTransactionCount(owner.address);
    fd = await factory.connect(owner).deploy(220, {
      nonce: _nonce,
      value: sendedEth,
      maxPriorityFeePerGas: BigNumber.from(15 * 10 ** 9),
      maxFeePerGas: BigNumber.from(30 * 10 ** 9),
    });
    // console.log( fd.deployTransaction)
    await fd.deployed();
  });

  it("permission transfer test", async function () {
    expect(await fd.owner()).to.eq(owner.address);

    let tx = await fd.changeOperator(operator.address, overrideData);

    await tx.wait();
    expect(await fd.operator()).to.eq(operator.address);

    await expect(fd.connect(operator).changeOwner(operator.address, overrideData)).to.be.reverted;
    await expect(fd.connect(user.address).changeOperator(operator.address, overrideData)).to.be.reverted;

    await fd.connect(operator).changeOperator(user.address, overrideData);
    expect(await fd.operator()).to.eq(user.address);

    await expect(fd.connect(operator.address).changeOwner(user.address, overrideData)).to.be.reverted;
  });

  it("operator with different permissions test", async function () {
    expect(await fd.owner()).to.eq(owner.address);
    await fd.changeOperator(operator.address, overrideData);
    expect(await fd.operator()).to.eq(operator.address);

    // expect write revert
    await expect(writeTest(fd.connect(user), "0x01", 100, 1)).to.be.reverted;
    await expect(writeChunkTest(fd.connect(user), "0x01", 0, 1000, 1)).to.be.reverted;

    // expect write succeed
    await writeTest(fd.connect(owner), "0x01", 100, 1);
    await writeChunkTest(fd.connect(owner), "0x01", 1, 1000, 1);

    // expect remove revert
    await expect(removeTest(fd.connect(user), "0x01")).to.be.reverted;
    await expect(removeChunkTest(fd.connect(user), "0x01", 0)).to.be.reverted;

    // expect remove succeed
    await removeChunkTest(fd.connect(owner), "0x01", 1);
    await removeTest(fd.connect(owner), "0x01");
    await readTest(fd.connect(user), "0x01", 0, 0, 0, 0, 0, 0);
  });

  it("verify contract balance after write operation", async function () {
    let totalTokenConsumed = BigNumber.from(0);

    // verify FaatDirectory contract balance
    expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth);
    // set operator
    await fd.changeOperator(operator.address, overrideData);

    // need stake one eth
    let data0 = Array.from({ length: ChunkSize }, () => Math.floor(Math.random() * 256));
    let tx = await fd.connect(operator).write("0x01", data0, overrideData);
    await tx.wait();
    expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth.sub(ETH));
    totalTokenConsumed = totalTokenConsumed.add(ETH);

    // need stake two eth
    let data1 = Array.from({ length: ChunkSize * 2 }, () => Math.floor(Math.random() * 256));
    tx = await fd.connect(operator).write("0x02", data1, overrideData);
    await tx.wait();
    expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth.sub(ETH.mul(2)).sub(totalTokenConsumed));
    totalTokenConsumed = totalTokenConsumed.add(ETH.mul(2));

    // do not need stake
    let storageSlotCodeLen = await fd.storageSlotCodeLength();
    let v = await fd.calculateValueForData(ChunkSize.sub(storageSlotCodeLen));
    console.log("need value", v.toString());
    expect(v).to.eq(BigNumber.from(0));

    let data2 = Array.from({ length: ChunkSize.sub(storageSlotCodeLen) }, () => Math.floor(Math.random() * 256));
    tx = await fd.connect(operator).write("0x03", data2, overrideData);
    await tx.wait();
    expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth.sub(totalTokenConsumed));
  });

  // it("write and remove test", async function () {
  //   let totalTokenConsumed = BigNumber.from(0);

  //   // verify FaatDirectory contract balance
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth);
  //   // set operator
  //   let tx = await fd.changeOperator(operator.address, overrideData);
  //   await tx.wait();

  //   // need stake one eth
  //   let data0 = Array.from({ length: ChunkSize }, () => Math.floor(Math.random() * 256));
  //   tx = await fd.connect(operator).write("0x01", data0, overrideData);
  //   await tx.wait();
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth.sub(ETH));
  //   totalTokenConsumed = totalTokenConsumed.add(ETH);

  //   tx = await fd.connect(operator).remove("0x01", overrideData);
  //   await tx.wait();
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth);
  // });

  // it("writeChunk and removeChunk test", async function () {
  //   let totalTokenConsumed = BigNumber.from(0);

  //   // verify FaatDirectory contract balance
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth);
  //   // set operator
  //   await fd.changeOperator(operator.address, overrideData);

  //   // need stake one eth
  //   let data0 = Array.from({ length: ChunkSize }, () => Math.floor(Math.random() * 256));
  //   let tx = await fd.connect(operator).writeChunk("0x01", 0, data0, overrideData);
  //   await tx.wait();
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth.sub(ETH));
  //   totalTokenConsumed = totalTokenConsumed.add(ETH);

  //   tx = await fd.connect(operator).removeChunk("0x01", 0, overrideData);
  //   await tx.wait();
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth);
  // });

  // it("refund with different permissions test", async function () {
  //   // verify FaatDirectory contract balance
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth);
  //   // set operator
  //   await fd.changeOperator(operator.address, overrideData);

  //   // refund fail
  //   await expect(fd.connect(operator).refund(overrideData)).to.be.reverted;

  //   // refund succeed
  //   await fd.connect(owner).refund(overrideData);
  // });

  // it("destruct with different permissions test", async function () {
  //   // verify FaatDirectory contract balance
  //   expect(await ethers.provider.getBalance(fd.address)).to.eq(sendedEth);
  //   // set operator
  //   await fd.changeOperator(operator.address, overrideData);

  //   // refund fail
  //   await expect(fd.connect(operator).destruct(overrideData)).to.be.reverted;

  //   // refund succeed
  //   await fd.connect(owner).destruct(overrideData);
  // });

  // it("nonpayable test", async function () {
  //   let data0 = Array.from({ length: 100 }, () => Math.floor(Math.random() * 256));

  //   // expect failed when msg.value > 0
  //   await expect(
  //     fd
  //       .connect(operator)
  //       .writeChunk("0x01", 0, data0, {
  //         value: ETH,
  //         maxPriorityFeePerGas: BigNumber.from(16 * 10 ** 9),
  //         maxFeePerGas: BigNumber.from(31 * 10 ** 9),
  //       })
  //   ).to.be.reverted;
  //   await expect(
  //     fd
  //       .connect(operator)
  //       .write("0x02", data0, {
  //         value: ETH,
  //         maxPriorityFeePerGas: BigNumber.from(16 * 10 ** 9),
  //         maxFeePerGas: BigNumber.from(31 * 10 ** 9),
  //       })
  //   ).to.be.reverted;

  //   // only owner can send token to contract
  //   await web3.eth.sendTransaction({
  //     from: owner.address,
  //     to: fd.address,
  //     value: ETH,
  //     maxFeePerGas: BigNumber.from(31 * 10 ** 9),
  //     maxPriorityFeePerGas: BigNumber.from(16 * 10 ** 9),
  //   });

  //   // expect revert
  //   await expect(
  //     web3.eth.sendTransaction({
  //       from: operator.address,
  //       to: fd.address,
  //       value: ETH,
  //       maxFeePerGas: BigNumber.from(31 * 10 ** 9),
  //       maxPriorityFeePerGas: BigNumber.from(16 * 10 ** 9),
  //     })
  //   ).to.be.reverted;
  // });
});
