const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { defaultAbiCoder } = require("ethers/lib/utils");

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

  it("write/truncate chunks", async function () {
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

    let data2 = Array.from({ length: 30 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.writeChunk("0x616263", 2, data2);
    expect(await fd.readChunk("0x616263", 2)).to.eql([
      ethers.utils.hexlify(data2),
      true,
    ]);

    await fd.truncate("0x616263", 3); // should do nothing
    expect(await fd.size("0x616263")).to.eql([ToBig(60), ToBig(3)]);
    expect(await fd.countChunks("0x616263")).to.eql(ToBig(3));
    expect(await fd.read("0x616263")).to.eql([
      ethers.utils.hexlify(data0.concat(data1).concat(data2)),
      true,
    ]);

    await fd.truncate("0x616263", 1); // should succeed
    expect(await fd.size("0x616263")).to.eql([ToBig(10), ToBig(1)]);
    expect(await fd.read("0x616263")).to.eql([
      ethers.utils.hexlify(data0),
      true,
    ]);
    expect(await fd.readChunk("0x616263", 1)).to.eql(["0x", false]);
    expect(await fd.countChunks("0x616263")).to.eql(ToBig(1));
  });

  it("readFile through fallback ", async function () {
    const FlatDirectory = await ethers.getContractFactory("FlatDirectory");
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    expect(await fd.countChunks("0x616263")).to.eql(ToBig(0));

    let data0 = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 256)
    );

    // read file "/abc" through url as "/abc" will succeed
    await fd.write("0x616263", data0);

    calldata = "0x2f616263";

    let returndata = await web3.eth.call({
      to: fd.address,
      data: calldata,
    });

    let rData = defaultAbiCoder.decode(["bytes"], returndata);
    expect(rData.toString()).to.equal(ethers.utils.hexlify(data0));
  });

  it("set default file and read default file through fallback ", async function () {
    const FlatDirectory = await ethers.getContractFactory("FlatDirectory");
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    let indexFile = web3.utils.asciiToHex("index.html");
    // set default file
    await fd.setDefault(indexFile);

    let data0 = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 256)
    );

    // access file "/index.html" with url as "/" will succeed
    await fd.write(indexFile, data0);

    calldata = "0x2f";
    let returndata = await web3.eth.call({
      to: fd.address,
      data: calldata,
    });

    let rData = defaultAbiCoder.decode(["bytes"], returndata);
    expect(rData.toString()).to.equal(ethers.utils.hexlify(data0));

    // access file "/dir1/index.html" with url as "/dir1/" will succeed
    let secondaryIndexFile = web3.utils.asciiToHex("dir1/index.html");
    let data1 = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 256)
    );

    await fd.write(secondaryIndexFile, data1);
    calldata1 = web3.utils.asciiToHex("/dir1/");
    let returndata1 = await web3.eth.call({
      to: fd.address,
      data: calldata1,
    });

    let rdata1 = defaultAbiCoder.decode(["bytes"], returndata1);
    expect(rdata1.toString()).to.equal(ethers.utils.hexlify(data1));

    // access file "/dir1/index.html" with url as "/dir1" will fail
    calldata1 = web3.utils.asciiToHex("/dir1");
    returndata1 = await web3.eth.call({
      to: fd.address,
      data: calldata1,
    });
    rdata1 = defaultAbiCoder.decode(["bytes"], returndata1);
    console.log(rdata1.toString());
    expect(rdata1.toString()).to.equal("0x");
  });
});
