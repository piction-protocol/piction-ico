const { timer } = require("./helpers/timer");

var Pxl = artifacts.require("PXL");

const colors = require('colors/safe');

const BigNumber = web3.BigNumber;

require("chai")
    .use(require("chai-as-promised"))
    .use(require("chai-bignumber")(BigNumber))
    .should();

contract('PXL', function(accounts) {
    const owner = accounts[0];
    const notOwner = accounts[1];
    const userOne = accounts[2];
    const userTwo = accounts[3];

    const decimals = Math.pow(10, 18);
    const initialBalance = 10000 * decimals;
    const sendPXL = 3000 * decimals;
    const userSendPXL = 100 * decimals;

    let token;

    let beforeBalance;
    let afterBalance;
    let txFee;
    let accumulate = 0;
    let won = 450000;

    it("setup contract ", async () => {
        console.log(colors.red.bold("\t++++++++ 1ETH to 450,000 won ++++++++"));

        console.log();
        console.log(colors.magenta.bold("\t========== Deploy contract gas usage(1 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(notOwner);

        token = await Pxl.new({from: notOwner, gasPrice: 1000000000}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(notOwner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\ttoken contract"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();

        console.log();
        console.log(colors.magenta.bold("\t========== TransferOwnership gas usage(1 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(notOwner);

        await token.transferOwnership(owner, {from: notOwner, gasPrice: 1000000000}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(notOwner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\ttransferOwnership"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();


        console.log();
        console.log(colors.magenta.bold("\t========== Mint gas usage(1 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(owner);

        await token.mint(initialBalance, {from: owner, gasPrice: 1000000000}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(owner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\ttoken mint"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();
    });

    it ("check initial balance", async () => {
        const balance = await token.balanceOf.call(owner);
        balance.should.be.bignumber.equal(initialBalance);
    });

    it ("send 3000 pixel to userOne", async () => {
        console.log();
        console.log(colors.magenta.bold("\t========== Token transfer gas usage(1 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(owner);

        await token.transfer(userOne, sendPXL, {from: owner, gasPrice: 1000000000}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(owner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\tpxl transfer 3000"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();
    });

    it ("check token transfer", async () => {
        const ownerBalance = await token.balanceOf.call(owner);
        ownerBalance.should.be.bignumber.equal(initialBalance - sendPXL);

        const userOneBalance = await token.balanceOf.call(userOne);
        userOneBalance.should.be.bignumber.equal(sendPXL);
    });

    it ("notOwner token transfer", async () => {
        await token.transfer(notOwner, sendPXL, {from: owner, gasPrice: 1000000000}).should.be.fulfilled;
        await token.transfer(userOne, sendPXL, {from: notOwner, gasPrice: 1000000000}).should.be.rejected;
    });

    it ("unlock", async () => {
        await token.approve(userTwo, userSendPXL, {from: userOne, gasPrice: 1000000000}).should.be.fulfilled;
        await token.transferFrom(userOne, userTwo, userSendPXL, {from: userTwo, gasPrice: 1000000000}).should.be.rejected;
        await token.transfer(userTwo, userSendPXL, {from: userOne, gasPrice: 1000000000}).should.be.rejected;

        console.log();
        console.log(colors.magenta.bold("\t========== unlock gas usage(1 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(owner);

        await token.unlock({from: owner, gasPrice: 1000000000}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(owner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\tunlock"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();

        await token.transfer(userTwo, userSendPXL, {from: userOne, gasPrice: 1000000000}).should.be.fulfilled;
        await token.transferFrom(userOne, userTwo, userSendPXL, {from: userTwo, gasPrice: 1000000000}).should.be.fulfilled;
    });
});
