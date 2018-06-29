const Enquirer = require('enquirer');
const fs = require('fs');
const input = JSON.parse(fs.readFileSync('build/contracts/Product.json'));
const contract = new web3.eth.Contract(input.abi);
const replace = require('replace-in-file');

module.exports = async () => {
    let enquirer = new Enquirer();
    enquirer.question('name', 'product name');
    enquirer.question('maxcap', 'maxcap(ETH)');
    enquirer.question('exceed', 'exceed(ETH)');
    enquirer.question('minimum', 'minimum(ETH)');
    enquirer.question('rate', 'rate');
    enquirer.question('lockup', 'lockup (day)');
    let answer = await enquirer.prompt(['name', 'maxcap', 'exceed', 'minimum', 'rate', 'lockup']);
    if (!answer.name ||
        answer.name.length == 0 ||
        Number(answer.maxcap) < 0 ||
        Number(answer.exceed) < 0 ||
        Number(answer.minimum) < 0 ||
        parseInt(answer.rate) < 0 ||
        parseInt(answer.lockup) < 0) return;

    let instance = await contract.deploy({
        data: input.bytecode,
        arguments: [answer.name, ether(answer.maxcap), ether(answer.exceed), ether(answer.minimum), answer.rate, answer.lockup]
    }).send(sendDefaultParams);

    replace({
        files: `.env.${process.env.NODE_ENV}`,
        from: /PRODUCT_ADDRESS=.*/g,
        to: `PRODUCT_ADDRESS=${instance.options.address}`
    });

    console.log(instance.options.address);

    return instance;
};