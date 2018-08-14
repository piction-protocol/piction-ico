const { ether } = require("./helpers/ether");

var Pxl = artifacts.require("PXL");
var Product = artifacts.require("Product");
var TokenDistributor = artifacts.require("TokenDistributor");

const BigNumber = web3.BigNumber;

require("chai")
    .use(require("chai-as-promised"))
    .use(require("chai-bignumber")(BigNumber))
    .should();

contract("TOKENDISTRIBUTOR", function (accounts) {
    const owner = accounts[0];
    const secondOwner = accounts[1]; //sale contract
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
        tokenDistributor = await TokenDistributor.new({from: owner});

        await tokenDistributor.addOwner(secondOwner, {from: owner});
        await tokenDistributor.setToken(token.address, {from: owner});
        await token.transfer(tokenDistributor.address, tokenDistributorBalance, {from: owner});
    });

    describe("initialized", () => {
        it("Check initial balance", async () => {
            console.log("Owner address :", owner);
            const balance = await token.balanceOf.call(tokenDistributor.address);
            console.log("tokenDistributor balance :", balance);
            balance.should.be.bignumber.equal(tokenDistributorBalance)
        });
    });

    describe("addPurchased", () => {
        it("Insert", async () => {
            const insertToken = 1000;
            await tokenDistributor.addPurchased(buyer1, product.address, insertToken, insertToken, {from: secondOwner})
            .should.be.fulfilled;
        });
    });


});
