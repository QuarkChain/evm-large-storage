const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

exports.writeTest =  async function writeTest(fd, key, filesize, context) {
  const data = [];
  for (let i = 0; i < filesize; i++) {
    data.push(context);
  }

  let tx1 = await fd.write(key, data);
  await tx1.wait();

  let [resData] = await fd.read(key);

  let [fsize] = await fd.size(key);

  expect(BigNumber.from(data).toHexString()).to.eq(resData);
  expect(fsize.toNumber()).to.eq(filesize);
};

exports.writeChunkTest =  async function writeChunkTest(fd, key, chunkId, filesize, context) {
  const data = [];
  for (let i = 0; i < filesize; i++) {
    data.push(context);
  }

  let tx1 = await fd.writeChunk(key, chunkId, data);
  await tx1.wait();

  let [resData] = await fd.readChunk(key, chunkId);
  let [fsize] = await fd.chunkSize(key, chunkId);

  if (data.length == 0) {
    // deal with special case: return data is null
    expect(resData).to.eq("0x");
    expect(fsize.toNumber()).to.eq(0);
  } else {
    expect(BigNumber.from(data).toHexString()).to.eq(resData);
    expect(fsize.toNumber()).to.eq(filesize);
  }
};

exports.removeTest =  async function removeTest(fd, key) {
  let tx1 = await fd.remove(key);
  await tx1.wait();
};

exports.removeChunkTest =  async function removeChunkTest(fd, key, chunkId) {
  let tx1 = await fd.removeChunk(key, chunkId);
  await tx1.wait();
};

exports.readTest = async function readTest(
  fd,
  key,
  filesize1,
  context1,
  filesize2,
  context2,
  filesize3,
  context3
) {
  const data = [];
  for (let i = 0; i < filesize1; i++) {
    data.push(context1);
  }
  for (let i = 0; i < filesize2; i++) {
    data.push(context2);
  }
  for (let i = 0; i < filesize3; i++) {
    data.push(context3);
  }

  let [resData] = await fd.read(key);
  let [fsize] = await fd.size(key);

  if (data.length == 0) {
    // deal with special case: return data is null
    expect(resData).to.eq("0x");
    expect(fsize.toNumber()).to.eq(0);
  } else {
    expect(BigNumber.from(data).toHexString()).to.eq(resData);
    expect(fsize.toNumber()).to.eq(filesize1 + filesize2 + filesize3);
  }
};

