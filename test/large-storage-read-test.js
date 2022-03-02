const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

var ToBig = (x) => ethers.BigNumber.from(x);

describe("FlatDirectory Large Read Test", function () {
  it("large read/write", async function () {
    const FlatDirectory = await ethers.getContractFactory("FlatDirectoryTest");
    const fd = await FlatDirectory.deploy();
    await fd.deployed();

    // let nchunk = 85;  // 85 * 12 * 1024 ~ 1M
    let nchunk = 10;
    let data = [];

    for (let i = 0; i < nchunk; i++) {
      let data0 = Array.from({ length: 12 * 1024 }, () =>
        Math.floor(Math.random() * 256)
      );
      await fd.writeChunk("0x616263", i, data0);
      data = data.concat(data0);
    }

    // just for gas metering
    await (await fd.readNonView("0x616263")).wait();
    await (await fd.readManual("0x616263")).wait();

    // for comparison
    // 85 chunks
    // - readNonView: 12844889
    // - readManual: 3278113
  });
});
