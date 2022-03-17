const { web3 } = require("hardhat");
const { expect} = require("chai")
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");




let StoreInSlot_tester = async function (size){
    const StoreInSlot = await ethers.getContractFactory(
        "StoreInSlot"
    );

    const  sis = await StoreInSlot.deploy();
    await sis.deployed();
    console.log("StoreInSlot deploy succeed! Address:",sis.address)

    const value = [];
    for(let i = 0; i < size ; i++){
        value.push(1)
    }

    let tx1 = await sis.storeData(value);
    // console.log("txHash:",tx1.hash);
    // console.log("txInput:",tx1);
    let receipt1 =await tx1.wait(1);
    // console.log("第一次存储gas 消耗:",receipt1.gasUsed.toString());

    // 第二次存储跟第一次完全不同的数据
    for(let i = 0; i < size ; i++){
        value[i] = 2;
    }

    let tx2 = await sis.storeData(value);
    // console.log("txHash:",tx2.hash);
    let receipt2 =await tx2.wait(1);
    // console.log("第二次存储gas 消耗:",receipt2.gasUsed.toString());

    // 第三次存储跟第二次相同的数据
    tx2 = await sis.storeData(value);
    // console.log("txHash:",tx2.hash);
    let receipt3 =await tx2.wait(1);
    // console.log("第三次存储gas 消耗:",receipt3.gasUsed.toString());

    // check data length
    // 这里不要用HexStr,因为需要补0
    let length = ethers.BigNumber.from(size).toNumber();
    await checkLen(sis,0, length);

    // check data
    let expectValue = value.slice(0,32);
    let ev = ethers.BigNumber.from(expectValue);
    for (let i=1; i*32 <size ; i++){
        await checkData(sis,i,ev.toHexString());
    }
    
    printGas(size.toString(),receipt1,receipt2,receipt3);
}

let checkLen = async function (contract ,slot = 0, expectLen ){
    let data = await contract.getData(slot);
    let length = BigNumber.from(data).toNumber();
    // console.log("length:",slot,"  data:",expectLen);
    expect(length).to.equal(expectLen);
}

let checkData = async function (contract ,slot=1, expectValue ){
    let data = await contract.getData(slot);
    // console.log("slot:",slot,"  data:",data);
    expect(data).to.equal(expectValue);
}

describe("Store In Slot Gas Test",function () {

    for (let size=32;size<=4096;size*=2){
        let Info = "StoreInSlot test " + size.toString() + " byte"
        it(Info,async function () {
            await StoreInSlot_tester(size);
        })
    }
})

