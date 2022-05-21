const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let local_tester = async function (size, puts = 1) {
  const StorageManager = await ethers.getContractFactory(
    "StorageManagerLocalTest"
  );
  const sm = await StorageManager.deploy();
  await sm.deployed();

  const value = [];
  for (let i = 0; i < size; i++) {
    value.push(1);
  }

  for (let i = 0; i < puts; i++) {
    await sm.put(
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      value
    );
  }
  await sm.getWithoutView(
    "0x0000000000000000000000000000000000000000000000000000000000000000"
  );
};

let large_tester = async function (size, puts = 1) {
  const StorageManager = await ethers.getContractFactory("StorageManagerTest");
  const sm = await StorageManager.deploy(0);
  await sm.deployed();

  const value = [];
  for (let i = 0; i < size; i++) {
    value.push(1);
  }

  for (let i = 0; i < puts; i++) {
    await sm.put(
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      value
    );
  }
  await sm.getWithoutView(
    "0x0000000000000000000000000000000000000000000000000000000000000000"
  );
};

let large2_tester = async function (size, puts = 1) {
  const StorageManager = await ethers.getContractFactory("StorageManagerTest");
  const sm = await StorageManager.deploy(0);
  await sm.deployed();

  const value = [];
  for (let i = 0; i < size; i++) {
    value.push(1);
  }

  for (let i = 0; i < puts; i++) {
    await sm.put2(
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      value
    );
  }
  await sm.getWithoutView(
    "0x0000000000000000000000000000000000000000000000000000000000000000"
  );
};

describe("StorageManager Gas Test", function () {
  it("put/get non-replace 1k", async function () {
    await large_tester(1024);
  });

  it("put/get non-replace 4k", async function () {
    await large_tester(4096);
  });

  it("put/get non-replace 8k", async function () {
    await large_tester(8192);
  });

  it("put/get non-replace 12k", async function () {
    await large_tester(12288);
  });

  it("put2/get non-replace 12k", async function () {
    await large2_tester(12288);
  });

  //   it("put/get non-replace 16k", async function () {
  //     await large_tester(16384);
  //   });

  it("put/get inplace 12k", async function () {
    await large_tester(12288, 2);
  });

  it("put/get non-replace 1k (local storage)", async function () {
    await local_tester(1024);
  });

  it("put/get non-replace 4k (local storage)", async function () {
    await local_tester(4096);
  });

  it("put/get non-replace 8k (local storage)", async function () {
    await local_tester(8192);
  });

  it("put/get non-replace 12k (local storage)", async function () {
    await local_tester(12288);
  });

  //   it("put/get non-replace 16k (local storage)", async function () {
  //     await local_tester(16384);
  //   });

  it("put/get inplace 12k (local storage)", async function () {
    await local_tester(12288, 2);
  });
});
