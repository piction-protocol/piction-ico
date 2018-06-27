const Enquirer = require('enquirer');
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/TokenDistributor.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');

module.exports = async () => {
    if (!process.env.PXL_ADDRESS) {
        error('PXL_ADDRESS is not registered. Please .env.{network} file update!')
        return;
    }
    let enquirer = new Enquirer();
    enquirer.register('confirm', require('prompt-confirm'));
    enquirer.question('confirmPXLAddress', `confirm PXL_ADDRESS : ${process.env.PXL_ADDRESS}`, {type: 'confirm'});
    let answer = await enquirer.prompt(['confirmPXLAddress']);
    if (!answer.confirmPXLAddress) return;

    contract.deploy({
        data: input.bytecode,
        arguments: [process.env.PXL_ADDRESS]
    })
        .send(sendDefaultParams)
        .then(async newContractInstance => {
            log(`TOKEN_DISTRIBUTOR_ADDRESS : ${newContractInstance.options.address}`);
            enquirer.register('confirm', require('prompt-confirm'));
            enquirer.question('status', `update ${process.env.NODE_ENV} env`, {type: 'confirm'});
            answer = await enquirer.prompt(['status']);
            if (!answer.status) return;
            replace({
                files: `.env.${process.env.NODE_ENV}`,
                from: /TOKEN_DISTRIBUTOR_ADDRESS=.*/g,
                to: `TOKEN_DISTRIBUTOR_ADDRESS=${newContractInstance.options.address}`
            })
        });
};