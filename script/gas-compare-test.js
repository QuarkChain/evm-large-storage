const { ethers } = require("hardhat");
var fs = require("fs");
const { BigNumber } = require("ethers");
let printGas = function (size, r1, r2) {
  const context = `${size.toString()}byte          ${r1.gasUsed}          ${
    r2.gasUsed
  } \n`;
  // console.log(context);
  writeInFile(context);
};

let writeInFile = function (str) {
  fs.appendFileSync("GasCostCompare.txt", str, function (err) {
    if (err) {
      return console.error(err);
    }
  });
};

let WriteCode = async function (size) {
  const value = [];
  for (let i = 0; i < size; i++) {
    value.push(1);
  }

  let fdFactory = await ethers.getContractFactory("FlatDirectory");

  let opfd = await fdFactory.deploy(220);
  await opfd.deployed();

  let fd = await fdFactory.deploy(0);
  await fd.deployed();

  let tx1 = await fd.writeChunk("0x01", 0, value);
  let receipt1 = await tx1.wait(1);
  // console.log("gasUsed:",receipt1.gasUsed.toString())

  let tx2 = await opfd.writeChunk("0x01", 0, value);
  let receipt2 = await tx2.wait(1);

  // console.log("gasUsed:",receipt2.gasUsed.toString())
  printGas(size, receipt1, receipt2);
};

let run = async function () {
  writeInFile("size          normal          optimize\n");

  const MaxSize = 300;
  for (let size = 28; size <= MaxSize; size += 32) {
    await WriteCode(size);
  }
};

run();
