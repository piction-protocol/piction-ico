const Enquirer = require('enquirer');
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/TokenDistributor.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');

module.exports = async (pxlAddress) => {
    let instance = await contract.deploy({
        data: input.bytecode,
        arguments: [pxlAddress]
    }).send(sendDefaultParams);

    process.env.TOKEN_DISTRIBUTOR_ADDRESS = instance.options.address;
    replace({
        files: `.env.${process.env.NODE_ENV}`,
        from: /TOKEN_DISTRIBUTOR_ADDRESS=.*/g,
        to: `TOKEN_DISTRIBUTOR_ADDRESS=${instance.options.address}`
    });

    console.log(instance.options.address);

    return instance;
};