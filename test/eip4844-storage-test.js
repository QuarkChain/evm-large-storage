const {ethers} = require("hardhat");
const {expect} = require("chai");
const {utils} = require("ethers");
const sha3 = require('js-sha3').keccak_256;

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
    }
}

const createLocalHash = function (length) {
    const arr = Array(length).fill(1);
    const buf = Buffer.from(arr);
    let localHash = '0x' + sha3(buf);
    // bytes32 to bytes24
    localHash = localHash.substring(0, localHash.length - (32 - 24) * 2);
    // bytes24 to bytes32
    localHash = localHash + '0000000000000000';
    return localHash;
}

const uploadFile = async function (hexName, file, fileSize, storage, ercBlob) {
    let chunks = [];
    // Data need to be sliced if file > 126.976k， 1 blob = 4096 * 31 = 126.976k
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
        const result = await ercBlob.writeChunk(hexName, chunkIds, sizes, {value: value});
        const receipt = await result.wait(1);

        // upload real data
        for (let j = 0; j < maxCount; j++) {
            const log = iFace.parseLog(receipt.logs[j]);
            const Key = log.args[0];
            await uploadCallData(storage, Key, chunkDatas[j]);
        }
    }
}

describe("4844 Blob Storage Test", function () {
    let storage;
    let ercBlob;
    beforeEach(async () => {
        const EthStorageContractTest = await ethers.getContractFactory("EthStorageContractTest");
        storage = await EthStorageContractTest.deploy();
        await storage.deployed();

        const ERC5018ForBlob = await ethers.getContractFactory("ERC5018ForBlob");
        ercBlob = await ERC5018ForBlob.deploy();
        await ercBlob.deployed();

        await ercBlob.setEthStorageContract(storage.address);
    });

    it("put/get", async function () {
        // put
        const fileName = 'test.txt';
        const hexName = '0x' + Buffer.from(fileName, 'utf8').toString('hex');
        const fileSize = BLOB_SIZE * 2 + 1024;
        const localFile = Buffer.from(Array(fileSize).fill(1));
        await uploadFile(hexName, localFile, fileSize, storage, ercBlob);

        // get
        // file size
        const size = await ercBlob.size(hexName);
        expect(size[0]).to.equal(fileSize);

        // chunk count
        const chunkCount = await ercBlob.countChunks(hexName);
        expect(chunkCount).to.equal(3);


        // chunk size
        const chunkSize_0 = await ercBlob.chunkSize(hexName, 0);
        expect(chunkSize_0[0]).to.equal(BLOB_SIZE);

        const chunkSize_1 = await ercBlob.chunkSize(hexName, 1);
        expect(chunkSize_1[0]).to.equal(BLOB_SIZE);

        const chunkSize_2 = await ercBlob.chunkSize(hexName, 2);
        expect(chunkSize_2[0]).to.equal(fileSize - BLOB_SIZE * 2);


        // chunk hash
        const chunkHash_0 = await ercBlob.getChunkHash(hexName, 0);
        const localHash_0 = createLocalHash(BLOB_SIZE);
        expect(chunkHash_0).to.equal(localHash_0);

        const chunkHash_1 = await ercBlob.getChunkHash(hexName, 1);
        const localHash_1 = createLocalHash(BLOB_SIZE);
        expect(chunkHash_1).to.equal(localHash_1);

        const chunkHash_2 = await ercBlob.getChunkHash(hexName, 2);
        const localHash_2 = createLocalHash(fileSize - BLOB_SIZE * 2);
        expect(chunkHash_2).to.equal(localHash_2);


        // file hash
        const result = await ercBlob.read(hexName);
        const file = Buffer.from(ethers.utils.toUtf8String(result[0]));
        const fileHash = '0x' + sha3(file);
        const localHash = '0x' + sha3(localFile);
        expect(fileHash).to.equal(localHash);
    });

    it("remove", async function () {
        // put
        const fileName = 'test.txt';
        const hexName = '0x' + Buffer.from(fileName, 'utf8').toString('hex');
        let fileSize = BLOB_SIZE * 4;
        let localFile = Buffer.from(Array(fileSize).fill(1));
        await uploadFile(hexName, localFile, fileSize, storage, ercBlob);

        // remove chunk
        await ercBlob.removeChunk(hexName, 3);
        let size = await ercBlob.size(hexName);
        expect(size[0]).to.equal(BLOB_SIZE * 3);

        // truncate
        await ercBlob.truncate(hexName, 1);
        size = await ercBlob.size(hexName);
        expect(size[0]).to.equal(BLOB_SIZE);

        // remove file
        await ercBlob.remove(hexName);
        // file size
        size = await ercBlob.size(hexName);
        expect(size[0]).to.equal(0);
    });
});
