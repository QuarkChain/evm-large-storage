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


describe("OptimizedStorageManagerTest Test", function () {
    let  OptimizedStorageManagerTest

    beforeEach(async()=>{
        let factory = await ethers.getContractFactory("OptimizedStorageManagerTest")
        OptimizedStorageManagerTest = await factory.deploy()
        await OptimizedStorageManagerTest.deployed()
    })

    it("writefile :min 192Byte",async function(){
       await oneStoreTest(OptimizedStorageManagerTest,100,1)
    })

    it("writefile :equal 192Byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,192,1)
    })

    it("writefile :Over 192byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,250,2)
    })

    it("writefile :Over 192byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,250,2)
    })

    it("rewrite file :first 192byte ; second 300byte ;third 100byte",async function(){
        await oneStoreTest(OptimizedStorageManagerTest,192,1)

        await oneStoreTest(OptimizedStorageManagerTest,300,2)

        await oneStoreTest(OptimizedStorageManagerTest,100,1)
    })

    
})