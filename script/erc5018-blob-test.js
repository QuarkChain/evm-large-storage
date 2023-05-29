const { ethers } = require("hardhat");
const sha3 = require('js-sha3').keccak_256;
const { utils } = require("ethers");

const BLOB_SIZE = 4096 * 31;
const MAX_BLOB_COUNT = 2;

const Abi = [
  "event PutBlob(bytes32 key, uint256 blobIdx, uint256 length)"
];

const bufferBlob = function (buffer) {
  let i = 0;
  let result = [];
  const len = buffer.length;
  while (i < len) {
    result.push(buffer.slice(i, i += BLOB_SIZE));
  }
  return result;
}

const bufferChunk = function (buffer, chunkSize) {
  let i = 0;
  let result = [];
  const len = buffer.length;
  const chunkLength = Math.ceil(len / chunkSize);
  while (i < len) {
    result.push(buffer.slice(i, i += chunkLength));
  }
  return result;
}

const uploadCallData = async function (storage, Key, buffer) {
  const hexName = Key;
  const fileSize = buffer.length;

  let chunks = [];
  if (fileSize > 24 * 1024 - 326) {
    const chunkSize = Math.ceil(fileSize / (24 * 1024 - 326));
    chunks = bufferChunk(buffer, chunkSize);
  } else {
    chunks.push(buffer);
  }

  for (const index in chunks) {
    const chunk = chunks[index];
    const hexData = '0x' + chunk.toString('hex');
    // upload data
    const tx = await storage.writeBlobChunk(hexName, index, hexData, {
      gasLimit: 30000000
    });
    console.log(`Blob Chunk Transaction Id: ${tx.hash}`);
  }
}

const uploadFile = async function (hexName, fileSize, storage, ercBlob) {
  const arr = Array(fileSize).fill(1);
  const file = Buffer.from(arr);

  let chunks = [];
  // Data need to be sliced if file > 124K， 1 blob = 4096 * 31 = 124kb
  if (fileSize > BLOB_SIZE) {
    chunks = bufferBlob(file);
  } else {
    chunks.push(file);
  }

  const iFace = new utils.Interface(Abi);
  const cost = await ercBlob.upfrontPayment();
  for (let i = 0, length = chunks.length; i < length; i += MAX_BLOB_COUNT) {
    const maxCount = i + MAX_BLOB_COUNT > length ? i + MAX_BLOB_COUNT - length : MAX_BLOB_COUNT;

    const chunkDatas = [];
    const chunkIds = [];
    const sizes = [];
    // new chunk
    for (let j = 0; j < maxCount; j++) {
      const chunkId = i + j;
      chunkDatas.push(chunks[chunkId]);
      chunkIds.push(chunkId);
      sizes.push(chunks[chunkId].length);
    }

    const value = cost.mul(chunkIds.length);
    // upload file
    const result = await ercBlob.writeChunk(hexName, chunkIds, sizes, { value: value });
    console.log(`\nBlob Transaction Id: ${result.hash}`);
    const receipt = await result.wait(1);

    // upload real data
    for (let j = 0; j < maxCount; j++) {
      const log = iFace.parseLog(receipt.logs[j]);
      const Key = log.args[0];

      console.log(`Blob Size: ${chunkDatas[j].length}`);
      console.log(`Blob Chunk Key: ${Key}`);
      await uploadCallData(storage, Key, chunkDatas[j]);
    }
  }
}

let run = async function () {
  // init
  let EthStorageContractTest = await ethers.getContractFactory("EthStorageContractTest");
  let storage = await EthStorageContractTest.deploy();
  await storage.deployed();

  let ERC5018ForBlob = await ethers.getContractFactory("ERC5018ForBlob");
  let ercBlob = await ERC5018ForBlob.deploy();
  await ercBlob.deployed();

  await ercBlob.setEthStorageContract(storage.address);


  // upload
  console.log('start upload');
  const fileName = 'test.txt';
  const hexName = '0x' + Buffer.from(fileName, 'utf8').toString('hex');
  const fileSize = 2 * 128  * 1024;
  await uploadFile(hexName, fileSize, storage, ercBlob);


  // get
  const size = await ercBlob.size(hexName);
  console.log('\nFile size:', size[0].toString());

  const chunkSize = await ercBlob.chunkSize(hexName, 0);
  console.log('Chunk 0 size:', chunkSize[0].toString());

  const chunkHash = await ercBlob.getChunkHash(hexName, 0);
  const arr = Array(BLOB_SIZE).fill(1);
  const buf = Buffer.from(arr);
  const localHash = '0x' + sha3(buf);
  console.log('Chunk 0 hash:', chunkHash, localHash);

  const result = await ercBlob.read(hexName);
  const file = Buffer.from(ethers.utils.toUtf8String(result[0]));
  console.log(file.length, fileSize);
};

run();
