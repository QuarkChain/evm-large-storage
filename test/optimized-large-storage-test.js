const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

var ToBig = (x) => ethers.BigNumber.from(x);

let writeTest = async function(fd,key,filesize,context){

        const data = [];
        for (let i = 0; i < filesize; i++) {
             data.push(context);
        }

        let tx1 = await fd.write(key,data)
        await tx1.wait()

        let [resData,] = await fd.read(key)
        // console.log(resData)

        let [fsize,] = await fd.size(key)
        // console.log(fsize)

        expect(BigNumber.from(data).toHexString()).to.eq(resData)
        expect(fsize.toNumber()).to.eq(filesize)
}

let writeChunkTest = async function(fd,key,chunkId,filesize,context) {

        const data = [];
        for (let i = 0; i < filesize; i++) {
             data.push(context);
        }

        let tx1 = await fd.writeChunk(key,chunkId,data)
        await tx1.wait()

        let [resData,] = await fd.readChunk(key,chunkId)
        // console.log(resData)

        let [fsize,] = await fd.chunkSize(key,chunkId)
        // console.log(fsize)

        expect(BigNumber.from(data).toHexString()).to.eq(resData)
        expect(fsize.toNumber()).to.eq(filesize)
}

let removeTest = async function(fd,key){
    let tx1 = await fd.remove(key)
    await tx1.wait()
}

let removeChunkTest = async function(fd,key,chunkId){
    let tx1 = await fd.removeChunk(key,chunkId)
    await tx1.wait()
}

let readTest = async function(fd,key,filesize1,context1,filesize2,context2,filesize3,context3) {

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
    
    let [resData,] = await fd.read(key)
    let [fsize,] = await fd.size(key)

    // console.log("Size:",fsize)
    // console.log("Res Data:",resData)

    if (data.length == 0){
        // deal with special case: return data is null
        expect(resData).to.eq("0x")
        expect(fsize.toNumber()).to.eq(0)
    }else{
        expect(BigNumber.from(data).toHexString()).to.eq(resData)
        expect(fsize.toNumber()).to.eq(filesize1+filesize2+filesize3)
    }
    
}

describe("OptimizedFlatDirectory Test", function () {

    let OPFlatDirectory
    beforeEach(async()=>{
        factory = await ethers.getContractFactory("OptimizedFlatDirectory");
        OPFlatDirectory = await factory.deploy();
        await OPFlatDirectory.deployed();
    })

    it("read/write",async function(){
        await writeTest(OPFlatDirectory,"0x01",100,1)
        await writeTest(OPFlatDirectory,"0x02",1000,1)
        await writeTest(OPFlatDirectory,"0x03",10000,1)
    })

    it("rewrite",async function(){
        await writeTest(OPFlatDirectory,"0x01",100,1)
        await writeTest(OPFlatDirectory,"0x01",1000,2)
        await writeTest(OPFlatDirectory,"0x01",10000,3)
    })

    it("writeChunk",async function(){
        await writeChunkTest(OPFlatDirectory,"0x01",0,100,1)
        await writeChunkTest(OPFlatDirectory,"0x01",1,1000,2)
        await writeChunkTest(OPFlatDirectory,"0x01",2,10000,3)
    })

    it("rewrite through writeChunk",async function(){
        await writeChunkTest(OPFlatDirectory,"0x01",0,1000,1)
        await writeChunkTest(OPFlatDirectory,"0x01",1,1000,2)
        await writeChunkTest(OPFlatDirectory,"0x01",0,10000,4)
        // rewrite data in slot
        await writeChunkTest(OPFlatDirectory,"0x01",0,10,3)
        await writeChunkTest(OPFlatDirectory,"0x01",1,10,5)
    })

    it("read all chunk ",async function(){
        await writeChunkTest(OPFlatDirectory,"0x01",0,100,1)
        await writeChunkTest(OPFlatDirectory,"0x01",1,1000,2)
        await writeChunkTest(OPFlatDirectory,"0x01",2,10000,3)

        await readTest(OPFlatDirectory,"0x01",100,1,1000,2,10000,3)

        await writeChunkTest(OPFlatDirectory,"0x02",0,1000,1)
        await writeChunkTest(OPFlatDirectory,"0x02",1,10,2)
        await writeChunkTest(OPFlatDirectory,"0x02",2,100,3)

        await readTest(OPFlatDirectory,"0x02",1000,1,10,2,100,3)
    })

    it("write Chunk with NO_APPEND will revert",async function(){
        await writeChunkTest(OPFlatDirectory,"0x01",0,1000,1)
        await expect( writeChunkTest(OPFlatDirectory,"0x01",2,500,4)).to.be.reverted
    })

    it("remove test",async function(){
        await writeChunkTest(OPFlatDirectory,"0x01",0,1000,1)
        await writeChunkTest(OPFlatDirectory,"0x01",1,100,2)
        await writeChunkTest(OPFlatDirectory,"0x01",2,100,2)

        // remove testing
        await removeTest(OPFlatDirectory,"0x01")
        await readTest(OPFlatDirectory,0,0,0,0,0,0)

        // write again
        await writeChunkTest(OPFlatDirectory,"0x01",0,1000,1)
        await writeChunkTest(OPFlatDirectory,"0x01",1,100,2)
        await writeChunkTest(OPFlatDirectory,"0x01",2,100,2)
    })

    it("write/remove chunks", async function () {
        const FlatDirectory = await ethers.getContractFactory("OptimizedFlatDirectory");
        const fd = await FlatDirectory.deploy();
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
