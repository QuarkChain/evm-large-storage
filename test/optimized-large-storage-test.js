const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  writeChunkTest,
  writeTest,
  removeTest,
  removeChunkTest,
  readTest,
} = require("./shared/utils");

var ToBig = (x) => ethers.BigNumber.from(x);

describe("OptimizedFlatDirectory Test", function () {
  let OPFlatDirectory;
  beforeEach(async () => {
    factory = await ethers.getContractFactory("FlatDirectory");
    OPFlatDirectory = await factory.deploy(220);
    await OPFlatDirectory.deployed();
  });

  it("read/write", async function () {
    await writeTest(OPFlatDirectory, "0x01", 100, 1);
    await writeTest(OPFlatDirectory, "0x02", 1000, 1);
    await writeTest(OPFlatDirectory, "0x03", 10000, 1);
  });

  it("rewrite", async function () {
    await writeTest(OPFlatDirectory, "0x01", 100, 1);
    await writeTest(OPFlatDirectory, "0x01", 1000, 2);
    await writeTest(OPFlatDirectory, "0x01", 10000, 3);
  });

  it("writeChunk", async function () {
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 100, 1);
    await writeChunkTest(OPFlatDirectory, "0x01", 1, 1000, 2);
    await writeChunkTest(OPFlatDirectory, "0x01", 2, 10000, 3);
  });

  it("writeVariableSizedChunk", async function () {
    for (let size = 0; size < 300; size++) {
      await writeChunkTest(OPFlatDirectory, "0x01", 0, size, 1);
      await removeChunkTest(OPFlatDirectory, "0x01", 0);
    }
  });

  it("rewrite through writeChunk", async function () {
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 1000, 1);
    await writeChunkTest(OPFlatDirectory, "0x01", 1, 1000, 2);
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 10000, 4);
    // rewrite data in slot
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 10, 3);
    await writeChunkTest(OPFlatDirectory, "0x01", 1, 10, 5);
  });

  it("read all chunk ", async function () {
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 100, 1);
    await writeChunkTest(OPFlatDirectory, "0x01", 1, 1000, 2);
    await writeChunkTest(OPFlatDirectory, "0x01", 2, 10000, 3);

    await readTest(OPFlatDirectory, "0x01", 100, 1, 1000, 2, 10000, 3);

    await writeChunkTest(OPFlatDirectory, "0x02", 0, 1000, 1);
    await writeChunkTest(OPFlatDirectory, "0x02", 1, 10, 2);
    await writeChunkTest(OPFlatDirectory, "0x02", 2, 100, 3);

    await readTest(OPFlatDirectory, "0x02", 1000, 1, 10, 2, 100, 3);
  });

  it("write Chunk with NO_APPEND will revert", async function () {
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 1000, 1);
    await expect(writeChunkTest(OPFlatDirectory, "0x01", 2, 500, 4)).to.be
      .reverted;
  });

  it("remove test", async function () {
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 1000, 1);
    await writeChunkTest(OPFlatDirectory, "0x01", 1, 100, 2);
    await writeChunkTest(OPFlatDirectory, "0x01", 2, 100, 2);

    // remove testing
    await removeTest(OPFlatDirectory, "0x01");
    await readTest(OPFlatDirectory, 0, 0, 0, 0, 0, 0);

    // write again
    await writeChunkTest(OPFlatDirectory, "0x01", 0, 1000, 1);
    await writeChunkTest(OPFlatDirectory, "0x01", 1, 100, 2);
    await writeChunkTest(OPFlatDirectory, "0x01", 2, 100, 2);
  });

  it("write/remove chunks", async function () {
    const fd = OPFlatDirectory;

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
