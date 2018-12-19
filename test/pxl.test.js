var Pxl = artifacts.require("PXL");

const colors = require('colors/safe');
const BigNumber = web3.BigNumber;

require("chai")
    .use(require("chai-as-promised"))
    .use(require("chai-bignumber")(BigNumber))
    .should();

contract('PXL', function(accounts) {
    const newOwner = accounts[1];
    const deployOwner = accounts[2];
    const addOwner = accounts[3];
    const user1 = accounts[4];

    const decimals = Math.pow(10, 18);
    const initialBalance = 10000 * decimals;
    const sendPXL = 3000 * decimals;
    const ownerPXL = 100 * decimals;

    let token;

    let beforeBalance;
    let afterBalance;
    let txFee;
    let won = 150000;
    let fastGwei = 15000000000;

    it("setup contract ", async () => {
        console.log(colors.red.bold("\t++++++++ 1ETH to 150,000 won ++++++++"));

        console.log();
        console.log(colors.magenta.bold("\t========== Deploy contract gas usage(15 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(deployOwner);

        token = await Pxl.new({from: deployOwner, gasPrice: fastGwei}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(deployOwner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\ttoken contract"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();

        console.log();
        console.log(colors.magenta.bold("\t========== TransferOwnership gas usage(15 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(deployOwner);

        await token.transferOwnership(newOwner, {from: deployOwner, gasPrice: fastGwei}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(deployOwner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\ttransferOwnership"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();


        console.log();
        console.log(colors.magenta.bold("\t========== Mint gas usage(15 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(newOwner);

        await token.mint(initialBalance, {from: newOwner, gasPrice: fastGwei}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(newOwner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\ttoken mint"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();
    });

    it ("check initial balance", async () => {
        const balance = await token.balanceOf.call(newOwner);
        balance.should.be.bignumber.equal(initialBalance);
    });

    it ("send 3000 pixel to user1", async () => {
        console.log();
        console.log(colors.magenta.bold("\t========== Token transfer gas usage(15 Gwei) =========="));

        beforeBalance = await web3.eth.getBalance(newOwner);

        await token.transfer(user1, sendPXL, {from: newOwner, gasPrice: fastGwei}).should.be.fulfilled;

        afterBalance = await web3.eth.getBalance(newOwner);
        txFee = beforeBalance - afterBalance;
        console.log(colors.magenta("\tpxl transfer 3000"));
        console.log(colors.magenta("\tActual Tx Cost/Fee : " + txFee / decimals + " Ether (￦ " + Math.round((txFee / decimals) * won) + ")"));
        console.log();
    });

    it ("check token transfer", async () => {
        const ownerBalance = await token.balanceOf.call(newOwner);
        ownerBalance.should.be.bignumber.equal(initialBalance - sendPXL);

        const user1Balance = await token.balanceOf.call(user1);
        user1Balance.should.be.bignumber.equal(sendPXL);
    });

    it ("deployOwner token transfer", async () => {
        await token.transfer(newOwner, sendPXL, {from: deployOwner, gasPrice: fastGwei}).should.be.rejected;
    });

    it ("add contract owner", async() => {
        await token.addOwner(addOwner, {from: newOwner, gasPrice: fastGwei}).should.be.fulfilled;

        const isOwner = await token.isOwner.call(addOwner);
        isOwner.should.be.equal(true);

        await token.transfer(addOwner, ownerPXL, {from: newOwner, gasPrice: fastGwei}).should.be.fulfilled;

        let addOwnerBalance = await token.balanceOf.call(addOwner);
        addOwnerBalance.should.be.bignumber.equal(ownerPXL);

        await token.transfer(newOwner, ownerPXL/2, {from: addOwner, gasPrice: fastGwei}).should.be.fulfilled;
        addOwnerBalance = await token.balanceOf.call(addOwner);
        addOwnerBalance.should.be.bignumber.equal(ownerPXL/2);

        await token.mint(ownerPXL/2, {from: addOwner, gasPrice: fastGwei}).should.be.fulfilled;
        addOwnerBalance = await token.balanceOf.call(addOwner);
        addOwnerBalance.should.be.bignumber.equal(ownerPXL);
    });

    it ("remove contract owner", async() => {
        await token.removeOwner(addOwner, {from: newOwner, gasPrice: fastGwei}).should.be.fulfilled;
        
        const isOwner = await token.isOwner.call(addOwner);
        isOwner.should.be.equal(false);

        let addOwnerBalance = await token.balanceOf.call(addOwner);
        addOwnerBalance.should.be.bignumber.equal(ownerPXL);

        await token.transfer(newOwner, ownerPXL, {from: addOwner, gasPrice: fastGwei}).should.be.fulfilled;
        addOwnerBalance = await token.balanceOf.call(addOwner);
        addOwnerBalance.should.be.bignumber.equal(0);

        await token.mint(ownerPXL, {from: addOwner, gasPrice: fastGwei}).should.be.rejected;
        addOwnerBalance = await token.balanceOf.call(addOwner);
        addOwnerBalance.should.be.bignumber.equal(0);
    });
});
