const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/PXL.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');
const BigNumber = require('bignumber.js');
const decimals = Math.pow(10, 18);

module.exports = async (initialSupply) => {
    let instance = await contract.deploy({
        data: input.bytecode,
        arguments: [new BigNumber(initialSupply * decimals)]
    }).send(sendDefaultParams);

    replace({
        files: `.env.${process.env.NODE_ENV}`,
        from: /PXL_ADDRESS=.*/g,
        to: `PXL_ADDRESS=${instance.options.address}`
    });

    log(`PXL ADDRESS : ${instance.options.address}`);

    return instance;
};