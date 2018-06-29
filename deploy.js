require('dotenv-flow').config({default_node_env: 'ropsten'});
const colors = require('colors');
const Enquirer = require('enquirer');
const BigNumber = require('bignumber.js');
global.Web3 = require('web3');
global.web3 = new Web3(new Web3.providers.HttpProvider(`https://${process.env.NODE_ENV}.infura.io/`));

global.log = (message) => console.log(colors.green.bold(message));
global.error = (message) => console.log(colors.red.bold(message));
global.ether = (value) => new BigNumber(value * Math.pow(10, 18));

if (process.env.PRIVATE_KEY) {
    web3.eth.accounts.wallet.add(process.env.PRIVATE_KEY);
    log(`CURRENT_ADDRESS : ${web3.eth.accounts.wallet[0].address}`);
} else {
    error(`Please register your private key! (.env.${process.env.NODE_ENV} file)`)
    process.exit(0)
}

global.sendDefaultParams = {
    from: web3.eth.accounts.wallet[0].address,
    gas: 4500000,
    gasPrice: '1000000000'
}

const enquirer = new Enquirer();
const questions = [{
    type: 'radio',
    name: 'result',
    message: 'Which contract would you like to distribute?',
    choices: ['InitICO', 'Product', 'WhiteList']
}];
enquirer.register('radio', require('prompt-radio'));
enquirer.ask(questions)
    .then((answers) => require(`./scripts/${answers.result}.js`)())
    .catch((err) => log(err));