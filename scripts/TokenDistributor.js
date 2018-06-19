require('./App');

const input = JSON.parse(fs.readFileSync('build/contracts/TokenDistributor.json'));
const enquirer = new Enquirer();

if (process.env.TOKEN_DISTRIBUTOR_ADDRESS) {
    log(`TOKEN_DISTRIBUTOR_ADDRESS : ${process.env.TOKEN_DISTRIBUTOR_ADDRESS}`)
} else {
    error('TOKEN_DISTRIBUTOR_ADDRESS : Not registered yet!')
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

const deploy = async () => {
    if (!process.env.PXL_ADDRESS) {
        error('PXL_ADDRESS is not registered. Please .env.{network} file update!')
        return;
    }
    let enquirer = new Enquirer();
    enquirer.register('confirm', require('prompt-confirm'));
    enquirer.question('confirmPXLAddress', `confirm PXL_ADDRESS : ${process.env.PXL_ADDRESS}`, {type: 'confirm'});
    let answer = await enquirer.prompt(['confirmPXLAddress']);
    if (!answer.confirmPXLAddress) return;

    let contract = new web3.eth.Contract(input.abi);
    contract.deploy({
        data: input.bytecode,
        arguments: [process.env.PXL_ADDRESS]
    })
        .send(sendDefaultParams)
        .then(async newContractInstance => {
            log(`TOKEN_DISTRIBUTOR_ADDRESS : ${newContractInstance.options.address}`);
            enquirer.register('confirm', require('prompt-confirm'));
            enquirer.question('status', `update ${process.env.NODE_ENV} env`, {type: 'confirm'});
            answer = await enquirer.prompt(['status']);
            if (!answer.status) return;
            replace({
                files: `.env.${process.env.NODE_ENV}`,
                from: /TOKEN_DISTRIBUTOR_ADDRESS=.*/g,
                to: `TOKEN_DISTRIBUTOR_ADDRESS=${newContractInstance.options.address}`
            })
        });
};