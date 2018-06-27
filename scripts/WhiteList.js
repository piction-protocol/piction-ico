const Enquirer = require('enquirer');
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/Whitelist.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');

module.exports = async () => {
    contract.deploy({
        data: input.bytecode,
        arguments: []
    })
        .send(sendDefaultParams)
        .then(async newContractInstance => {
            log(`WHITELIST ADDRESS : ${newContractInstance.options.address}`);
            let enquirer = new Enquirer();
            enquirer.register('confirm', require('prompt-confirm'));
            enquirer.question('status', `update ${process.env.NODE_ENV} env`, {type: 'confirm'});
            answer = await enquirer.prompt(['status']);
            if (!answer.status) return;
            replace({
                files: `.env.${process.env.NODE_ENV}`,
                from: /WHITELIST_ADDRESS=.*/g,
                to: `WHITELIST_ADDRESS=${newContractInstance.options.address}`
            })
        });
};