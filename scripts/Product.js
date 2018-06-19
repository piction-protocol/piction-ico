require('./App');

const input = JSON.parse(fs.readFileSync('build/contracts/Product.json'));

const questions = [{
    type: 'radio',
    name: 'result',
    message: 'Which function do you want to run?',
    choices: ['deploy']
}];
let enquirer = new Enquirer();
enquirer.register('radio', require('prompt-radio'));
enquirer.ask(questions)
    .then((answers) => eval(answers.result)())
    .catch((err) => log(err));

const deploy = async () => {
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

    let contract = new web3.eth.Contract(input.abi);
    contract.deploy({
        data: input.bytecode,
        arguments: [answer.name, ether(answer.maxcap), ether(answer.exceed), ether(answer.minimum), answer.rate, answer.lockup]
    })
        .send(sendDefaultParams)
        .then(async newContractInstance => {
            log(`PRODUCT_ADDRESS : ${newContractInstance.options.address}`);
            enquirer.register('confirm', require('prompt-confirm'));
            enquirer.question('status', `update ${process.env.NODE_ENV} env`, {type: 'confirm'});
            answer = await enquirer.prompt(['status']);
            if (!answer.status) return;
            replace({
                files: `.env.${process.env.NODE_ENV}`,
                from: /PRODUCT_ADDRESS=.*/g,
                to: `PRODUCT_ADDRESS=${newContractInstance.options.address}`
            })
        });
};