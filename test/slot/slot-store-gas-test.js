const { web3 } = require("hardhat");
const { expect} = require("chai")
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { string } = require("hardhat/internal/core/params/argumentTypes");


let printGas = function print(size,r1,r2,r3){
    console.log(`${size.toString()} byte   ${r1.gasUsed}   ${r2.gasUsed}   ${r3.gasUsed}`)
}

let StoreInSlotByDynamicArray_tester = async function(size) {
    const StoreInSlotByDynamicArray = await ethers.getContractFactory(
        "StoreInSlotByDynamicArray"
    );

    const  sis = await StoreInSlotByDynamicArray.deploy();
    await sis.deployed();
    console.log("StoreInSlotByDynamicArray deploy succeed! Address:",sis.address)

    const value = [];
    for(let i = 0; i < size ; i++){
        value.push(1)
    }

    let tx1 = await sis.storeDataFirst(value);
    // console.log("txHash:",tx1.hash);
    // console.log("txInput:",tx1);
    let receipt1 =await tx1.wait(1);

    // 第二次存储跟第一次完全不同的数据
    for(let i = 0; i < size ; i++){
        value[i] = 2;
    }

    let tx2 = await sis.storeDataOverwrite(value);
    console.log("txHash:",tx2.hash);
    let receipt2 =await tx2.wait(1);

    // 第三次存储跟第二次相同的数据
    let tx3 = await sis.storeDataOverwrite(value);
    // console.log("txHash:",tx3.hash);
    let receipt3 =await tx3.wait(1);

    printGas(size,receipt1,receipt2,receipt3);

}

let StoreInSlot_common_tester = async function (name,size){
    const contract = await ethers.getContractFactory(
        name
    );

    const  sis = await contract.deploy();
    await sis.deployed();
    console.log("StoreInSlot deploy succeed! Address:",sis.address)

    const value = [];
    for(let i = 0; i < size ; i++){
        value.push(1)
    }

    let tx1 = await sis.storeData(value);
    console.log("txHash:",tx1.hash);
    // console.log("txInput:",tx1);
    let receipt1 =await tx1.wait(1);


    // 第二次存储跟第一次完全不同的数据
    for(let i = 0; i < size ; i++){
        value[i] = 2;
    }

    let tx2 = await sis.storeData(value);
    console.log("txHash:",tx2.hash);
    let receipt2 =await tx2.wait(1);


    // 第三次存储跟第二次相同的数据
    let tx3 = await sis.storeData(value);
    // console.log("txHash:",tx3.hash);
    let receipt3 =await tx3.wait(1);

    printGas(size,receipt1,receipt2,receipt3);
  
}

let StoreInRuntimeCode_tester = async function (size){

    const value = [];
    for(let i = 0; i < size ; i++){
        value.push(1);
    }
    let cf = await ethers.getContractFactory("StorageSlotFactoryFromInput");

    let ss = await cf.deploy(value);
    await ss.deployed();

    let tx =ss.deployTransaction;
    let receipt =await tx.wait(1);
    console.log("gasUsed:",receipt.gasUsed.toString());

}

describe("Store In Slot Gas Test",function () {

    for (let size=32;size<=4096;size*=2){
        let Info = "StoreInSlot test " + size.toString() + " byte"
        it(Info,async function () {
            await StoreInSlot_common_tester("StoreInSlot",size);
        })
    }

    for (let size=32;size<=4096;size*=2){
        let Info = "StoreInSlotByDynamicArray test " + size.toString() + " byte"
        it(Info,async function () {
            await StoreInSlotByDynamicArray_tester(size);
        })
    }
    
    for (let size=32;size<=4096;size*=2){
        let Info = "StoreInSlotByStaticArray test " + size.toString() + " byte"
        it(Info,async function () {
            await StoreInSlot_common_tester("StoreInSlotByStaticArray",size);
        })
    }

    for (let size=32;size<=4096;size*=2){
        let Info = "StoreInSlotByMap test " + size.toString() + " byte"
        it(Info,async function () {
            await StoreInSlot_common_tester("StoreInSlotByMap",size);
        })
    }
    
    for (let size=32;size<=4096;size*=2){
        let Info = "StoreInRuntimeCode test " + size.toString() + " byte"
        it(Info,async function () {
            await StoreInRuntimeCode_tester(size);
        })
    }

    // it("StoreInRuntimeCode_tester test 32byte",async function(){
    //     await StoreInRuntimeCode_tester(32)
    // })

    // it("StoreInRuntimeCode_tester test 64byte",async function(){
    //     await StoreInRuntimeCode_tester(64)
    // })

    // it("StoreInRuntimeCode_tester test 128byte",async function(){
    //     await StoreInRuntimeCode_tester(128)
    // })

    // it("StoreInRuntimeCode_tester test 160byte",async function(){
    //     await StoreInRuntimeCode_tester(160)
    // })


})

