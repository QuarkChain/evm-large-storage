const { web3,ethers } = require("hardhat");
const { expect } = require("chai");
const { Contract,BigNumber } = require("ethers");


describe("SlotHelper Library Test", function () {
    let  OptimizedStorageManagerTest
    const SHITLEFT160BIT = BigNumber.from(1).mul(16).pow(40)

    beforeEach(async()=>{
        let factory = await ethers.getContractFactory("OptimizedStorageManagerTest")
        OptimizedStorageManagerTest = await factory.deploy()
        await OptimizedStorageManagerTest.deployed()
    })

    // it("OptimizedStorageManagerTest/put & get", async function () {
    //     const len = 20;
    //     let res = await SlotHelperTest.encodeLen(len)
    //     let expectRes = BigNumber.from(len).mul(SHITLEFT160BIT).toHexString()

    //     expect(BigNumber.from(res).eq(expectRes)).to.eq(true)
    //     // console.log(BigNumber.from(len).mul(SHITLEFT160BIT).toHexString())
    //     // console.log(res);

    //     let resLen = await SlotHelperTest.decodeLen(res)
    //     expect(resLen.eq(BigNumber.from(len))).to.eq(true)
    // })

    it("OptimizedStorageManagerTest/ put & get :min 192Byte",async function(){
        let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"
        let data = "0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7dffff"
        let datalen = 34

        let tx1 = await OptimizedStorageManagerTest.put(key,data)
        await tx1.wait()
        let resData = await OptimizedStorageManagerTest.get(key)

        // let resLen = await OptimizedStorageManagerTest.getLen(key)

        expect(data).to.eq(resData)
        // expect(resLen.toNumber()).to.eq(datalen)
    })

    it("OptimizedStorageManagerTest/ put & get :equal 192Byte",async function(){
        let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"
        let data = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        let datalen = 34

        let tx1 = await OptimizedStorageManagerTest.put(key,data)
        await tx1.wait()
        let resData = await OptimizedStorageManagerTest.get(key)

        // let resLen = await OptimizedStorageManagerTest.getLen(key)

        expect(data).to.eq(resData)
        // expect(resLen.toNumber()).to.eq(datalen)
    })

    it("OptimizedStorageManagerTest/ put & get :Over 192byte",async function(){
        let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"
        let data = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        // let datalen = 34

        let tx1 = await OptimizedStorageManagerTest.put(key,data)
        await tx1.wait()
        let resData = await OptimizedStorageManagerTest.get(key)

        // let resLen = await OptimizedStorageManagerTest.getLen(key)

        expect(data).to.eq(resData)
        // expect(resLen.toNumber()).to.eq(datalen)
    })



    
})