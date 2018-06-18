const { ether } = require("./helpers/ether");

var Pxl = artifacts.require("PXL");
var Product = artifacts.require("Product");
var TokenDistributor = artifacts.require("TokenDistributor");
var Sale = artifacts.require("Sale");
var Whitelist = artifacts.require("Whitelist");

const BigNumber = web3.BigNumber;

require("chai")
    .use(require("chai-as-promised"))
    .use(require("chai-bignumber")(BigNumber))
    .should();

contract("SALE", function (accounts) {
    const owner = accounts[0];
    const wallet = accounts[1];
    const unregistedOwner = accounts[2];

    const buyer1 = accounts[3];
    const buyer2 = accounts[4];
    const buyer3 = accounts[5];
    const buyer4 = accounts[6];

    const decimals = Math.pow(10, 18);
    const initialBalance = new BigNumber(100000 * decimals);
    const tokenDistributorBalance = new BigNumber(50000 * decimals);

    const oneDayMs = 86400000;
    const twoDayMs = 172800000;
    const overDayMs = new Date().getMilliseconds() + twoDayMs;

    const productName = "PrivateSale";
    const productMaxcap = 50;
    const productExceed = 20;
    const productMinimum = 1;
    const productRate = 1000;
    const productLockup = oneDayMs;
    const productLockup2 = twoDayMs;

    let token;
    let product;
    let tokenDistributor;
    let sale;
    let whitelist;

    before("Setup contract", async () => {
        token = await Pxl.new(initialBalance, {from: owner});
        product = await Product.new(
            productName,
            ether(productMaxcap),
            ether(productExceed),
            ether(productMinimum),
            productRate,
            productLockup,
            {from: owner});
        tokenDistributor = await TokenDistributor.new(token.address, {from: owner});

        whitelist = await Whitelist.new({from: owner});
        await whitelist.addAddressToWhitelist(buyer1, {from: owner});

        sale = await Sale.new(wallet, whitelist.address, product.address, tokenDistributor.address, {from: owner});
        await product.addOwner(sale.address, {from: owner});
        await tokenDistributor.addOwner(sale.address, {from: owner});

        await token.transfer(tokenDistributor.address, tokenDistributorBalance, {from: owner});
        await sale.start({from: owner});
    });

    describe("sendEther", () => {
        it("sendEther", async () => {
            const gas = 500000;
            const txFee = gas * web3.eth.gasPrice;

            try { await web3.eth.sendTransaction({ to: sale.address, value: ether(2), from: buyer1, gas: gas }); }
            catch(error) {
                console.log("error: ", error);
            }

            const amount = await tokenDistributor.getAmountFromBuyer.call(buyer1, product.address);
            console.log("amount: ", amount);
        });
    });
});
