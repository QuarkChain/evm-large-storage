const { web3,ethers } = require("hardhat");
const { expect } = require("chai");
const { Contract,BigNumber } = require("ethers");


let oneStoreTest = async function(osmt,filesize,where){
    let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"
        const data = [];
        for (let i = 0; i < filesize; i++) {
             data.push(1);
        }

        let tx1 = await osmt.put(key,data)
        await tx1.wait()
        let resData = await osmt.get(key)

        let fsize = await osmt.filesize(key)
        let _where = await osmt.whereStore(key)

        expect(BigNumber.from(data).toHexString()).to.eq(resData)
        expect(fsize.toNumber()).to.eq(filesize)
        expect(_where).to.eq(where)
}

let removeTest = async function(osmt){
    let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"

    // remove file
    let tx2 = await osmt.remove(key)
    await tx2.wait()
    fsize = await osmt.filesize(key)
    expect(fsize.toNumber()).to.eq(0)
}

describe("OptimizedStorageManagerTest Test", function () {
    let  OptimizedStorageManagerTest

    beforeEach(async()=>{
        let factory = await ethers.getContractFactory("StorageManagerTest")
        OptimizedStorageManagerTest = await factory.deploy(220)
        await OptimizedStorageManagerTest.deployed()
    })

    it("writefile :min 220Byte",async function(){
       await oneStoreTest(OptimizedStorageManagerTest,100,1)
    })

    it("writefile :equal 220Byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,220,1)
    })

    it("writefile :Over 220Byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,250,2)
    })

    it("rewrite file :first 220Byte ; second 300byte ;third 100byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,220,1)

        await oneStoreTest(OptimizedStorageManagerTest,300,2)

        await oneStoreTest(OptimizedStorageManagerTest,100,1)
    })

    it("write and remove file: filesize 100byte",async function(){

        await oneStoreTest(OptimizedStorageManagerTest,100,1)
        await removeTest(OptimizedStorageManagerTest)
    })

    it("write and remove file: filesize 300byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,300,2)
        await removeTest(OptimizedStorageManagerTest)
    })
    
    it("write and remove files multiple times: first filesize 100byte ; second filesize 300byte ; third filesize 1byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,100,1)
        await removeTest(OptimizedStorageManagerTest)

        await oneStoreTest(OptimizedStorageManagerTest,300,2)
        await removeTest(OptimizedStorageManagerTest)

        await oneStoreTest(OptimizedStorageManagerTest,1,1)
        await removeTest(OptimizedStorageManagerTest)
    })
})