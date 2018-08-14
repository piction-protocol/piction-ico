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

    const buyersPrivateSale = accounts.slice(3, 8);
    const buyersPreSale = accounts.slice(6, 15)

    const decimals = Math.pow(10, 18);
    const initialBalance = new BigNumber(100000000 * decimals);
    const tokenDistributorBalance = new BigNumber(50000000 * decimals);

    const oneDayMs = 86400000;

    let nowMs

    let token;
    let tokenDistributor;
    let sale;
    let whitelist;

    let privateProduct90
    let privateProduct60
    let privateProduct30

    let preProduct10

    let product;

    before("Setup contract", async () => {

        //Token Create
        token = await Pxl.new(initialBalance, {from: owner});

        //TokenDistributor Create
        tokenDistributor = await TokenDistributor.new({from: owner});

        //Whitelist Create
        whitelist = await Whitelist.new({from: owner});

        //Sale Create
        sale = await Sale.new(wallet, whitelist.address, tokenDistributor.address, {from: owner});

        //Add Owner
        await tokenDistributor.addOwner(sale.address, {from: owner});

        //Set Token
        await tokenDistributor.setToken(token.address, {from: owner});

        //Token Transfer : send to tokenDistributor
        await token.transfer(tokenDistributor.address, tokenDistributorBalance, {from: owner});
    });

    describe("initialized", () => {
        it("Check tokenDistributor balance", async() => {
            var balance = await token.balanceOf.call(tokenDistributor.address);
            balance.should.be.bignumber.equal(tokenDistributorBalance);
        });
    });

    describe("private sale", () => {
        before("prepare private sale", async () => {
            privateProduct90 = await Product.new(
                "90",
                ether(0),
                ether(0),
                ether(0),
                0,
                90,
                {from: owner}
            );

            privateProduct60 = await Product.new(
                "60",
                ether(0),
                ether(0),
                ether(0),
                0,
                60,
                {from: owner}
            );

            privateProduct30 = await Product.new(
                "30",
                ether(0),
                ether(0),
                ether(0),
                0,
                30,
                {from: owner}
            );
        });

        describe("purchased test", () => {
            it("unregisted owner - addPurchased", async () => {
                await tokenDistributor
                    .addPurchased(buyersPrivateSale[0], privateProduct90.address, ether(1000), ether(1), {from: unregistedOwner})
                    .should.be.rejected;
            });

            it("owner - addPurchased", async () => {
                await tokenDistributor
                    .addPurchased(buyersPrivateSale[0], privateProduct90.address, ether(1000), ether(1), {from: owner})
                    .should.be.fulfilled;

                await tokenDistributor
                    .addPurchased(buyersPrivateSale[1], privateProduct60.address, ether(2000), ether(2), {from: owner})
                    .should.be.fulfilled;

                await tokenDistributor
                    .addPurchased(buyersPrivateSale[2], privateProduct30.address, ether(3000), ether(3), {from: owner})
                    .should.be.fulfilled;

                await tokenDistributor
                    .addPurchased(buyersPrivateSale[3], privateProduct90.address, ether(3000), ether(3), {from: owner})
                    .should.be.fulfilled;

                await tokenDistributor
                    .addPurchased(buyersPrivateSale[2], privateProduct30.address, ether(1000), ether(1), {from: owner})
                    .should.be.fulfilled;
                var list = await tokenDistributor.getAllReceipt.call({from: owner})
                    list[0].length.should.be.equal(5);
            });
        });

        describe("release test", () => {
            nowMs = Date.now();

            it("criterionTime test", async () => {
                await tokenDistributor.releaseByCount(privateProduct30.address, 1, {from: owner})
                    .should.be.rejected;
            });

            it("unregisted owner - setCriterionTime test", async () => {
                await tokenDistributor.setCriterionTime(nowMs - (29 * oneDayMs), {from: unregistedOwner})
                    .should.be.rejected;
            });

            it("release lockup30 - now 29day test", async () => {
                await tokenDistributor.setCriterionTime(nowMs - (29 * oneDayMs), {from: owner})
                    .should.be.fulfilled;

                await tokenDistributor.releaseByCount(privateProduct30.address, 1, {from: owner})
                   .should.be.rejected;
            });

            it("unregisted owner - release lockup30 - now 30day test", async () => {
                await tokenDistributor.setCriterionTime(nowMs - (30 * oneDayMs), {from: owner})
                    .should.be.fulfilled;

                await tokenDistributor.releaseByCount(privateProduct30.address, 1, {from: unregistedOwner})
                    .should.be.rejected;
            });

            it("token unlock", async () => {
                token.unlock({from: unregistedOwner})
                    .should.be.rejected;

                token.unlock({from: owner})
                    .should.be.fulfilled;
            });

            it("owner - release lockup30 - now 30day test", async () => {
                await tokenDistributor.releaseByCount(privateProduct30.address, 100, {from: owner})
                    .should.be.fulfilled;
                var list = await tokenDistributor.getAllReceipt({from: owner});
                list[5][2].should.be.equal(true);
            });

            it("owner - release lockup60 - now 30day test", async () => {
                await tokenDistributor.releaseByCount(privateProduct60.address, 100, {from: owner})
                    .should.be.rejected;
            });

            it("owner - release lockup60 - now 90day test", async () => {
                await tokenDistributor.setCriterionTime(nowMs - (90 * oneDayMs), {from: owner})
                    .should.be.fulfilled;

                await tokenDistributor.releaseByCount(privateProduct60.address, 100, {from: owner})
                    .should.be.fulfilled;
            });

            it("buyerAddressTransfer test", async () => {
                await tokenDistributor.buyerAddressTransfer(1, buyersPrivateSale[0], buyersPrivateSale[4], {from: unregistedOwner})
                    .should.be.rejected;

                await tokenDistributor.buyerAddressTransfer(999, buyersPrivateSale[0], buyersPrivateSale[4], {from: owner})
                    .should.be.rejected;

                await tokenDistributor.buyerAddressTransfer(1, buyersPrivateSale[0], buyersPrivateSale[4], {from: owner})
                    .should.be.fulfilled;
            });

            it("owner - release lockup90 - now 90day test", async () => {
                await tokenDistributor.releaseByCount(privateProduct90.address, 100, {from: owner})
                    .should.be.fulfilled;
            });
        });
    });

    describe("pre sale", () => {
        before("prepare pre sale", async () => {
            preProduct10 = await Product.new(
                "preSale",
                ether(10),
                ether(2),
                ether(1),
                750,
                10,
                {from: owner}
            );
        });

        it ("registerProduct", async() => {
            await sale.registerProduct(preProduct10.address, {from: unregistedOwner})
                .should.be.rejected;

            await sale.registerProduct(preProduct10.address, {from: owner})
                .should.be.fulfilled;
        });

        describe("whitelist test", () => {
            it("unregisted owner - add whitelist", async () => {
                buyersPreSale.forEach(async (buyer) => {
                    await whitelist.addAddressToWhitelist(buyer, {from: unregistedOwner})
                    .should.be.rejected;
                });
            });

            it("owner - add whitelist", async () => {
                buyersPreSale.forEach(async (buyer) => {
                    await whitelist.addAddressToWhitelist(buyer, {from: owner})
                    .should.be.fulfilled;
                });
            });

            it("check whitelist", async () => {
                buyersPreSale.forEach(async (buyer) => {
                    var success = await whitelist.whitelist.call(buyer);
                    success.should.be.equal(true);
                });
            });
        });

        it("pre sale start", async() => {
            await sale.start({from: unregistedOwner})
                .should.be.rejected;

            await sale.start({from: owner})
                .should.be.fulfilled;
        });

        describe("sendEther", () => {
            it("sendEther", async () => {
                const gas = 500000;
                const txFee = gas * web3.eth.gasPrice;

                try { await web3.eth.sendTransaction({ to: sale.address, value: ether(2), from: buyersPreSale[0], gas: gas }); }
                catch(error) {
                    console.log("error: ", error);
                }

                try { await web3.eth.sendTransaction({ to: sale.address, value: ether(3), from: buyersPreSale[1], gas: gas }); }
                catch(error) {
                    console.log("error: ", error);
                }

                const receiptList = await tokenDistributor.getAllReceipt.call({from:owner})
                const numReceipt = receiptList[0].length;

                const FIELD_PRODUCT = 0;
                const FIELD_BUYER = 1;
                const FIELD_ID = 2;
                const FIELD_AMOUNT = 3;
                const FIELD_ETHERAMOUNT = 4;
                const FIELD_RELEASE = 5;
                const FIELD_REFUND = 6;

                let receiptStructs = [];
                for (let i = 0; i < numReceipt; i++) {
                    const receipt = {
                        product: receiptList[FIELD_PRODUCT][i],
                        buyer:  receiptList[FIELD_BUYER][i],
                        id: receiptList[FIELD_ID][i].toNumber(),
                        amount: receiptList[FIELD_AMOUNT][i].toNumber(),
                        etherAmount: receiptList[FIELD_ETHERAMOUNT][i].toNumber(),
                        release: receiptList[FIELD_RELEASE][i],
                        refund: receiptList[FIELD_REFUND][i]
                    };
                    receiptStructs.push(receipt);
                }

                console.log("receiptStructs : ", receiptStructs);

                //buyer1 get receiptList
                const buyer1ReceiptList = await tokenDistributor.getBuyerReceipt.call(buyersPreSale[0])
                const buyer1NumReceipt = buyer1ReceiptList[0].length;

                const FIELD_BUYER_PRODUCT  = 0;
                const FIELD_BUYER_ID = 1;
                const FIELD_BUYER_AMOUNT = 2;
                const FIELD_BUYER_ETHERAMOUNT = 3;
                const FIELD_BUYER_RELEASE = 4;
                const FIELD_BUYER_REFUND = 5;

                let buyer1ReceiptStructs = [];
                for (let i = 0; i < buyer1NumReceipt; i++) {
                    const buyer1Receipt = {
                        product:  buyer1ReceiptList[FIELD_BUYER_PRODUCT][i],
                        id: buyer1ReceiptList[FIELD_BUYER_ID][i].toNumber(),
                        amount: buyer1ReceiptList[FIELD_BUYER_AMOUNT][i].toNumber(),
                        etherAmount: buyer1ReceiptList[FIELD_BUYER_ETHERAMOUNT][i].toNumber(),
                        release: buyer1ReceiptList[FIELD_BUYER_RELEASE][i],
                        refund: buyer1ReceiptList[FIELD_BUYER_REFUND][i]
                    }
                    buyer1ReceiptStructs.push(buyer1Receipt);
                }

                console.log("buyer1ReceiptStructs : ", buyer1ReceiptStructs);
            });
        });
    });
});
