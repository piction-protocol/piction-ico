const Enquirer = require('enquirer');
const PXL = require('./PXL');
const WhiteList = require('./WhiteList');
const TokenDistributor = require('./TokenDistributor');
const Sale = require('./Sale');
const Product = require('./Product');

module.exports = async () => {
    let enquirer = new Enquirer();
    enquirer.question('initialSupply', 'initial supply');
    enquirer.question('wallet', 'wallet address');
    let answer = await enquirer.prompt(['initialSupply', 'wallet']);
    if (Number(answer.initialSupply) < 0 ||
        !answer.wallet || answer.wallet.length == 0) return;

    console.log('▶▶▶▶▶ Deploy PXL contract ◀◀◀◀◀');
    let pxl = await PXL(answer.initialSupply);
    console.log('▶▶▶▶▶ Deploy WhiteList contract ◀◀◀◀◀');
    let whiteList = await WhiteList();
    console.log('▶▶▶▶▶ Deploy TokenDistributor contract ◀◀◀◀◀');
    let tokenDistributor = await TokenDistributor(pxl.options.address);
    console.log('▶▶▶▶▶ Deploy Sale contract ◀◀◀◀◀');
    let sale = await Sale(answer.wallet, whiteList.options.address, tokenDistributor.options.address);
    console.log('▶▶▶▶▶ Deploy Product contract ◀◀◀◀◀');
    let product = await Product();
    console.log('▶▶▶▶▶ TokenDistributor.addOwner(sale) ◀◀◀◀◀');
    let receipt = await tokenDistributor.methods
        .addOwner(sale.options.address)
        .send(sendDefaultParams);
    log(`hash : ${receipt.transactionHash}`);

    log('=========== ADDRESS INFO ===========')
    log(`PXL : ${pxl.options.address}`)
    log(`WHITELIST : ${whiteList.options.address}`)
    log(`TOKEN DISTRIBUTOR : ${tokenDistributor.options.address}`)
    log(`SALE : ${sale.options.address}`)
    log(`PRODUCT : ${product.options.address}`)
};