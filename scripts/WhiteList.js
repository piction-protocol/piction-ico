const Enquirer = require('enquirer');
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/Whitelist.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');

module.exports = async () => {
    let instance = await contract.deploy({
        data: input.bytecode,
        arguments: []
    }).send(sendDefaultParams);

    process.env.WHITELIST_ADDRESS = instance.options.address;
    replace({
        files: `.env.${process.env.NODE_ENV}`,
        from: /WHITELIST_ADDRESS=.*/g,
        to: `WHITELIST_ADDRESS=${instance.options.address}`
    });

    log(`WHITELIST ADDRESS : ${instance.options.address}`);

    return instance;
};