const Enquirer = require('enquirer');
const BigNumber = require('bignumber.js');
const colors = require('colors/safe');
const decimals = Math.pow(10, 18);
const PXL = require('./PXL');
const WhiteList = require('./WhiteList');
const TokenDistributor = require('./TokenDistributor');
const Sale = require('./Sale');

function validationENV() {
    // validation address
    if (!process.env.COLD_WALLET_ADDRESS || process.env.COLD_WALLET_ADDRESS.length == 0) {
        error('COLD_WALLET_ADDRESS is not registered. Please .env.{network} file update!')
        return false;
    }
    if (!process.env.TOKEN_HOLDER_ADDRESS || process.env.TOKEN_HOLDER_ADDRESS.length == 0) {
        error('TOKEN_HOLDER_ADDRESS is not registered. Please .env.{network} file update!')
        return false;
    }
    // validation token amount
    let totalSupply = Number(process.env.TOTAL_SUPPLY);
    let saleAmount = Number(process.env.SALE_AMOUNT);
    let holderAmount = Number(process.env.HOLDER_AMOUNT);
    if (!totalSupply || totalSupply == 0) {
        error('TOTAL_SUPPLY = 0')
        return false;
    }
    if (saleAmount + holderAmount != totalSupply) {
        error('SALE_AMOUNT + HOLDER_AMOUNT != TOTAL_SUPPLY')
        return false;
    }
    return true;
}

function printENV() {
    console.log(colors.red.bold('>>>>>>>>>> ENV INFO <<<<<<<<<<'));
    console.log('- Address');
    console.log(` cold wallet address : ${process.env.COLD_WALLET_ADDRESS}`)
    console.log(` token holder address : ${process.env.TOKEN_HOLDER_ADDRESS}`)
    console.log('\n')
    console.log('- Token distribution');
    console.log(` total supply : ${process.env.TOTAL_SUPPLY}`)
    console.log(` sale amount : ${process.env.SALE_AMOUNT}`)
    console.log(` holder amount : ${process.env.HOLDER_AMOUNT}`)
    console.log('\n')
}

module.exports = async () => {

    if(!validationENV()) return;
    printENV();

    let enquirer = new Enquirer();
    enquirer.register('confirm', require('prompt-confirm'));
    enquirer.question('confirm', `Confirm ENV`, {type: 'confirm'});
    let answer = await enquirer.prompt(['confirm']);
    if (!answer.confirm) return;

    console.log('\n')
    console.log(colors.red.bold('> Deploy PXL contract'));
    let pxl = await PXL(process.env.TOTAL_SUPPLY);

    console.log(colors.red.bold('> Deploy WhiteList contract'));
    let whiteList = await WhiteList();

    console.log(colors.red.bold('> Deploy TokenDistributor contract'));
    let tokenDistributor = await TokenDistributor(pxl.options.address);

    console.log(colors.red.bold('> Deploy Sale contract'));
    let sale = await Sale(process.env.COLD_WALLET_ADDRESS, whiteList.options.address, tokenDistributor.options.address);

    console.log(colors.red.bold('> TokenDistributor.addOwner(sale)'));
    let receipt = await tokenDistributor.methods
        .addOwner(sale.options.address)
        .send(sendDefaultParams);
    console.log(`${receipt.transactionHash}`);

    console.log(colors.red.bold(`> PXL.transfer(tokenDistributor, ${process.env.SALE_AMOUNT})`));
    receipt = await pxl.methods
        .transfer(tokenDistributor.options.address, new BigNumber(process.env.SALE_AMOUNT * decimals))
        .send(sendDefaultParams);
    console.log(`${receipt.transactionHash}`);

    console.log(colors.red.bold(`> PXL.transfer(tokenHolder, ${process.env.HOLDER_AMOUNT})`));
    receipt = await pxl.methods
        .transfer(process.env.TOKEN_HOLDER_ADDRESS, new BigNumber(process.env.HOLDER_AMOUNT * decimals))
        .send(sendDefaultParams);
    console.log(`${receipt.transactionHash}`);

    console.log('\n')
    console.log(colors.red.bold('>>>>>>>>>> Deployed contract address <<<<<<<<<<'));
    console.log(`PXL : ${pxl.options.address}`)
    console.log(`WHITELIST : ${whiteList.options.address}`)
    console.log(`TOKEN DISTRIBUTOR : ${tokenDistributor.options.address}`)
    console.log(`SALE : ${sale.options.address}`)
};