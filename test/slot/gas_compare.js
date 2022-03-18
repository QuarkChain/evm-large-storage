const { ethers } = require("hardhat");
var fs = require("fs");
const { BigNumber } = require("ethers");
let printGas = function (size,r1,r2,r3){
    const context = `${size.toString()}byte          ${r1.gasUsed}          ${r2.gasUsed}          ${r3.gasUsed}\n`;
    console.log(context);
    writeInFile(context);
}

let writeInFile = function (str){
    fs.appendFileSync('gas_compare_under1k.txt', str,function(err){
        if (err) {
            return console.error(err)
        }
        // console.log("gas data have writed in gas_compare.txt");
    })
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

let StoreInRuntimeCode_tester = async function (size,contractCode){

    const value = [];
    for(let i = 0; i < size ; i++){
        value.push(1);
    }
    let res = value;
    if (contractCode.length>0) {
        let valueHex = BigNumber.from(value).toHexString().slice(2,);
        res = contractCode.concat(valueHex);
    }
    let cf = await ethers.getContractFactory("StorageSlotFactoryFromInput");

    let ss = await cf.deploy(res);
    await ss.deployed();

    let tx =ss.deployTransaction;
    let receipt =await tx.wait(1);
    console.log("gasUsed:",receipt.gasUsed.toString());

    printGas(size,receipt,receipt,receipt)
}

let run = async function(){
    writeInFile("size            first          second(diff)      third(same)\n");

    const MaxSize = 1024;
    writeInFile('\n---------Case StoreInSlot---------\n');
    for (let size=32;size<=MaxSize;size+=32){
        await StoreInSlot_common_tester("StoreInSlot",size);
    }

    writeInFile('\n---------Case StoreInSlotByDynamicArray---------\n');
    for (let size=32;size<=MaxSize;size+=32){
        await StoreInSlotByDynamicArray_tester(size);
    }
    
    writeInFile('\n-------Case StoreInSlotByStaticArray-------\n');
    for (let size=32;size<=MaxSize;size+=32){
        await StoreInSlot_common_tester("StoreInSlotByStaticArray",size);
    }

    writeInFile('\n-------Case StoreInSlotByMap---------\n');
    for (let size=32;size<=MaxSize;size+=32){
        await StoreInSlot_common_tester("StoreInSlotByMap",size);
    }
    
    writeInFile('\n-------Case StoreInRuntimeCode-------\n');
    for (let size=32;size<=MaxSize;size+=32){
        await StoreInRuntimeCode_tester(size,"")
    }

    let StorageSlotSelfDestructableContract =new String("0x6080604052348015600f57600080fd5b506004361060325760003560e01c80632b68b9c61460375780638da5cb5b14603f575b600080fd5b603d6081565b005b60657f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200160405180910390f35b336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161460ed5760405162461bcd60e51b815260206004820152600e60248201526d3737ba10333937b69037bbb732b960911b604482015260640160405180910390fd5b33fffea2646970667358221220fc66c9afb7cb2f6209ae28167cf26c6c06f86a82cbe3c56de99027979389a1be64736f6c63430008070033");
    writeInFile('\n-------Case StoreInRuntimeCodeWithSelfDestruct-------\n');
    for (let size=32;size<=MaxSize;size+=32){
        await StoreInRuntimeCode_tester(size,StorageSlotSelfDestructableContract);
    }
}

run();