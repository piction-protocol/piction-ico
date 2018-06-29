const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/Sale.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');

module.exports = async (wallet, whitelist, tokenDistributor) => {
    let instance = await contract.deploy({
        data: input.bytecode,
        arguments: [wallet, whitelist, tokenDistributor]
    }).send(sendDefaultParams);

    replace({
        files: `.env.${process.env.NODE_ENV}`,
        from: /SALE_ADDRESS=.*/g,
        to: `SALE_ADDRESS=${instance.options.address}`
    });

    console.log(instance.options.address);

    return instance;
};
