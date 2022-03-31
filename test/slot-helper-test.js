const { web3,ethers } = require("hardhat");
const { expect } = require("chai");
const { Contract,BigNumber } = require("ethers");


describe("SlotHelper Library Test", function () {
    let  SlotHelperTest
    const SHITLEFT224BIT = BigNumber.from(1).mul(16).pow(56)
    
    beforeEach(async()=>{
        let factory = await ethers.getContractFactory("SlotHelperTest")
        SlotHelperTest = await factory.deploy()
        await SlotHelperTest.deployed()
    })

    it("SlotHelper/encodeLen & decodeLen", async function () {
        const len = 20;
        let res = await SlotHelperTest.encodeLen(len)
        let expectRes = BigNumber.from(len).mul(SHITLEFT224BIT).toHexString()

        expect(BigNumber.from(res).eq(expectRes)).to.eq(true)

        let resLen = await SlotHelperTest.decodeLen(res)
        expect(resLen.eq(BigNumber.from(len))).to.eq(true)
    })

    it("SlotHelper/encodeMetadata & decodeMetadata & decodeMetadata1", async function () {
        const len = 20;
        const data = []
        for (let i=0;i<len;i++){
            data.push(1)
        }

        //return mdata = "0x0000001401010101010101010101010101010101010101010000000000000000"
        let mdata = await SlotHelperTest.encodeMetadata(data)
        console.log(mdata)
        
        //return [resLen1,resData1] = [20,"0x0101010101010101010101010101010101010101000000000000000000000000"]
        let [resLen1,resData1] = await SlotHelperTest.decodeMetadata(mdata)
        expect(resLen1.toNumber()).to.eq(len)

        //return [resLen2,resData2] = [20,"0x0101010101010101010101010101010101010101"]
        let [resLen2,resData2] = await SlotHelperTest.decodeMetadata1(mdata)
        console.log("resData2:",resData2)
        expect(resLen2.toNumber()).to.eq(len)
        expect(BigNumber.from(data).toHexString()).to.eq(resData2)

        // 20
        let resLen3 = await SlotHelperTest.decodeLen(mdata)
        expect(resLen2.eq(BigNumber.from(len))).to.eq(true)
    })

    it("SlotHelper/ put & get",async function(){
        let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"
        let data = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        let datalen = 17

        let tx1 = await SlotHelperTest.put(key,data)
        await tx1.wait()
        let resData = await SlotHelperTest.get(key)
        let resLen = await SlotHelperTest.getLen(key)

        expect(data).to.eq(resData)
        expect(resLen.toNumber()).to.eq(datalen)
    })

    it("SlotHelper/ put & get over 28byte",async function(){
        let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"
        let data = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        let datalen = 64

        let tx1 = await SlotHelperTest.put(key,data)
        await tx1.wait()
        let resData = await SlotHelperTest.get(key)
        let resLen = await SlotHelperTest.getLen(key)
        
        expect(data).to.eq(resData)
        expect(resLen.toNumber()).to.eq(datalen)
    })



    
})