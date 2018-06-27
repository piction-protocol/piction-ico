const Enquirer = require('enquirer');
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/Sale.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');

module.exports = async () => {
    if (!process.env.WALLET_ADDRESS) {
        error('WALLET_ADDRESS is not registered. Please .env.{network} file update!')
        return;
    }
    if (!process.env.WHITELIST_ADDRESS) {
        error('WHITELIST_ADDRESS is not registered. Please .env.{network} file update!')
        return;
    }
    if (!process.env.TOKEN_DISTRIBUTOR_ADDRESS) {
        error('TOKEN_DISTRIBUTOR_ADDRESS is not registered. Please .env.{network} file update!')
        return;
    }
    let enquirer = new Enquirer();
    enquirer.register('confirm', require('prompt-confirm'));
    enquirer.question('confirmWalletAddress', `confirm WALLET_ADDRESS : ${process.env.WALLET_ADDRESS}`, {type: 'confirm'});
    enquirer.question('confirmWhitelistAddress', `confirm WHITELIST_ADDRESS : ${process.env.WHITELIST_ADDRESS}`, {type: 'confirm'});
    enquirer.question('confirmTokenDistributorAddress', `confirm TOKEN_DISTRIBUTOR_ADDRESS : ${process.env.TOKEN_DISTRIBUTOR_ADDRESS}`, {type: 'confirm'});
    let answer = await enquirer.prompt(['confirmWalletAddress', 'confirmWhitelistAddress', 'confirmTokenDistributorAddress']);
    if (!answer.confirmWalletAddress || !answer.confirmWhitelistAddress || !answer.confirmTokenDistributorAddress) return;

    contract.deploy({
        data: input.bytecode,
        arguments: [process.env.WALLET_ADDRESS, process.env.WHITELIST_ADDRESS, process.env.TOKEN_DISTRIBUTOR_ADDRESS]
    })
        .send(sendDefaultParams)
        .then(async newContractInstance => {
            log(`SALE ADDRESS : ${newContractInstance.options.address}`);
            enquirer.register('confirm', require('prompt-confirm'));
            enquirer.question('status', `update ${process.env.NODE_ENV} env`, {type: 'confirm'});
            answer = await enquirer.prompt(['status']);
            if (!answer.status) return;
            replace({
                files: `.env.${process.env.NODE_ENV}`,
                from: /SALE_ADDRESS=.*/g,
                to: `SALE_ADDRESS=${newContractInstance.options.address}`
            })
        });
};
