require('./App');

const input = JSON.parse(fs.readFileSync('build/contracts/Whitelist.json'));
const enquirer = new Enquirer();

if (process.env.WHITELIST_ADDRESS) {
    log(`WHITELIST_ADDRESS : ${process.env.WHITELIST_ADDRESS}`)
} else {
    error('WHITELIST_ADDRESS : Not registered yet!')
}

const questions = [{
    type: 'radio',
    name: 'result',
    message: 'Which function do you want to run?',
    choices: ['deploy']
}];
enquirer.register('radio', require('prompt-radio'));
enquirer.ask(questions)
    .then((answers) => eval(answers.result)())
    .catch((err) => log(err));

const deploy = () => {
    let contract = new web3.eth.Contract(input.abi);
    contract.deploy({
        data: input.bytecode,
        arguments: []
    })
        .send(sendDefaultParams)
        .then(async newContractInstance => {
            log(`WHITELIST ADDRESS : ${newContractInstance.options.address}`);
            enquirer.register('confirm', require('prompt-confirm'));
            enquirer.question('status', `update ${process.env.NODE_ENV} env`, {type: 'confirm'});
            answer = await enquirer.prompt(['status']);
            if (!answer.status) return;
            replace({
                files: `.env.${process.env.NODE_ENV}`,
                from: /WHITELIST_ADDRESS=.*/g,
                to: `WHITELIST_ADDRESS=${newContractInstance.options.address}`
            })
        });
};