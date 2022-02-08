const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StorageManager Test", function () {
    it("put/get", async function () {
      const StorageManager = await ethers.getContractFactory("StorageManagerTest");
      const sm = await StorageManager.deploy();
      await sm.deployed();

      await sm.put("0x0000000000000000000000000000000000000000000000000000000000000000", "0x112233");
      expect(await sm.get("0x0000000000000000000000000000000000000000000000000000000000000000")).to.equal("0x112233");

      await sm.put("0x0000000000000000000000000000000000000000000000000000000000000000", "0x33221100");
      expect(await sm.get("0x0000000000000000000000000000000000000000000000000000000000000000")).to.equal("0x33221100");

      await sm.put("0x0000000000000000000000000000000000000000000000000000000000000001", "0x33221100aabbccdd");
      expect(await sm.get("0x0000000000000000000000000000000000000000000000000000000000000001")).to.equal("0x33221100aabbccdd");
      expect(await sm.get("0x0000000000000000000000000000000000000000000000000000000000000000")).to.equal("0x33221100");
    });
  }
);
