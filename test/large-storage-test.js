const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

var ToBig = (x) => ethers.BigNumber.from(x);

describe("FlatDirectory Test", function () {
  it("read/write", async function () {
    const FlatDirectory = await ethers.getContractFactory("FlatDirectory");
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    await fd.write("0x616263", "0x112233");
    expect(await fd.read("0x616263")).to.eql(["0x112233", true]);

    let data = Array.from({ length: 40 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.write("0x616263", data);
    expect(await fd.read("0x616263")).to.eql([
      ethers.utils.hexlify(data),
      true,
    ]);
    expect(await fd.size("0x616263")).to.eql([ToBig(40), ToBig(1)]);
  });

  it("read/write chunks", async function () {
    const FlatDirectory = await ethers.getContractFactory("FlatDirectory");
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    let data0 = Array.from({ length: 1024 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.write("0x616263", data0);
    expect(await fd.read("0x616263")).to.eql([
      ethers.utils.hexlify(data0),
      true,
    ]);

    let data1 = Array.from({ length: 512 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.writeChunk("0x616263", 1, data1);
    expect(await fd.readChunk("0x616263", 1)).to.eql([
      ethers.utils.hexlify(data1),
      true,
    ]);

    let data = data0.concat(data1);
    expect(await fd.read("0x616263")).to.eql([
      ethers.utils.hexlify(data),
      true,
    ]);
    expect(await fd.size("0x616263")).to.eql([ToBig(1536), ToBig(2)]);
  });

  it("write/remove chunks", async function () {
    const FlatDirectory = await ethers.getContractFactory("FlatDirectory");
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    expect(await fd.countChunks("0x616263")).to.eql(ToBig(0));

    let data0 = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.write("0x616263", data0);
    expect(await fd.read("0x616263")).to.eql([
      ethers.utils.hexlify(data0),
      true,
    ]);

    let data1 = Array.from({ length: 20 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.writeChunk("0x616263", 1, data1);
    expect(await fd.readChunk("0x616263", 1)).to.eql([
      ethers.utils.hexlify(data1),
      true,
    ]);

    await fd.removeChunk("0x616263", 0); // should do nothing
    expect(await fd.size("0x616263")).to.eql([ToBig(30), ToBig(2)]);
    expect(await fd.countChunks("0x616263")).to.eql(ToBig(2));
    expect(await fd.readChunk("0x616263", 0)).to.eql([
      ethers.utils.hexlify(data0),
      true,
    ]);

    await fd.removeChunk("0x616263", 1); // should succeed
    expect(await fd.size("0x616263")).to.eql([ToBig(10), ToBig(1)]);
    expect(await fd.read("0x616263")).to.eql([
      ethers.utils.hexlify(data0),
      true,
    ]);
    expect(await fd.readChunk("0x616263", 1)).to.eql(["0x", false]);
    expect(await fd.countChunks("0x616263")).to.eql(ToBig(1));
  });
});
