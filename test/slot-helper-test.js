const { web3,ethers } = require("hardhat");
const { expect } = require("chai");
const { Contract,BigNumber } = require("ethers");


describe("SlotHelper Library Test", function () {
    let  SlotHelperTest
    const SHITLEFT160BIT = BigNumber.from(1).mul(16).pow(40)

    beforeEach(async()=>{
        let factory = await ethers.getContractFactory("SlotHelperTest")
        SlotHelperTest = await factory.deploy()
        await SlotHelperTest.deployed()
    })

    it("SlotHelper/encodeLen & decodeLen", async function () {
        const len = 20;
        let res = await SlotHelperTest.encodeLen(len)
        let expectRes = BigNumber.from(len).mul(SHITLEFT160BIT).toHexString()

        expect(BigNumber.from(res).eq(expectRes)).to.eq(true)
        // console.log(BigNumber.from(len).mul(SHITLEFT160BIT).toHexString())
        // console.log(res);

        let resLen = await SlotHelperTest.decodeLen(res)
        expect(resLen.eq(BigNumber.from(len))).to.eq(true)
    })

    it("SlotHelper/ put & get",async function(){
        let key = "0x00000000000000000000000000000000000000000000000000000000000000aa"
        let data = "0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7dffff"
        let datalen = 34

        let tx1 = await SlotHelperTest.put(key,data)
        await tx1.wait()
        let resData = await SlotHelperTest.get(key)

        let resLen = await SlotHelperTest.getLen(key)

        expect(data).to.eq(resData)
        expect(resLen.toNumber()).to.eq(datalen)
    })



    
})