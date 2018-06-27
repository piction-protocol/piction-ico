const Enquirer = require('enquirer');
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/PXL.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');
const BigNumber = require('bignumber.js');
const decimals = Math.pow(10, 18);

module.exports = async () => {
    let enquirer = new Enquirer();
    enquirer.question('initialSupply', 'initialSupply');
    enquirer.question('confirmInitialSupply', 'initialSupply (confirm)');
    let answer = await enquirer.prompt(['initialSupply', 'confirmInitialSupply']);
    if (!Number(answer.initialSupply) || answer.initialSupply != answer.confirmInitialSupply) return;

    contract.deploy({
        data: input.bytecode,
        arguments: [new BigNumber(answer.initialSupply * decimals)]
    })
        .send(sendDefaultParams)
        .then(async newContractInstance => {
            log(`PXL ADDRESS : ${newContractInstance.options.address}`);
            enquirer.register('confirm', require('prompt-confirm'));
            enquirer.question('status', `update ${process.env.NODE_ENV} env`, {type: 'confirm'});
            answer = await enquirer.prompt(['status']);
            if (!answer.status) return;
            replace({
                files: `.env.${process.env.NODE_ENV}`,
                from: /PXL_ADDRESS=.*/g,
                to: `PXL_ADDRESS=${newContractInstance.options.address}`
            })
        });
};