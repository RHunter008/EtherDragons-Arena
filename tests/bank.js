var last_transaction_result;
var last_transaction_error;

var wallets = new Array(
    "0x17988AFeDDdD3AECC25FeAE9951718E1adF3b9e6", //CEO и создатель контрактов
    "0xaA7B1425d5f79386235c84E180874DA8B63dc292", //СMO 
    "0xF0f7d694CB9F632230EC4E9F17d98F5f69d6aaE4", //CFO
    "0x3C21f4Ab1A671e9cA085b55F895BA9fF8C3F1251" // тестовый кошель
);

//contracts
//Shares: https://ropsten.etherscan.io/tx/0xe856fffd5bc8a88be0fa285eaaeae42c1bb2dd25df56b5934d4610cdde65d011
var bankAddress = '0x7773550d7f64a839602bfce66ec9fdecf9c71a74';
var bankAbiArray = [
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": false,
                "name": "_monthNum",
                "type": "uint256"
            }
        ],
        "name": "NewMonth",
        "type": "event"
    },
    {
        "constant": false,
        "inputs": [],
        "name": "receive",
        "outputs": [],
        "payable": true,
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "name": "_sender",
                "type": "address"
            },
            {
                "indexed": false,
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "Withdraw",
        "type": "event"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_newCFO",
                "type": "address"
            },
            {
                "name": "_newCFOLimit",
                "type": "uint256"
            }
        ],
        "name": "setCFO",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_newCMO",
                "type": "address"
            },
            {
                "name": "_newCMOLimit",
                "type": "uint256"
            }
        ],
        "name": "setCMO",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_to",
                "type": "address"
            }
        ],
        "name": "setController",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_newProfitAddr",
                "type": "address"
            }
        ],
        "name": "setProfitAddr",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [],
        "name": "transferFunds",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "name": "_CMOAddress",
                "type": "address"
            },
            {
                "name": "_CFOAddress",
                "type": "address"
            },
            {
                "name": "_profitAddr",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "canTransfer",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "CEOAddress",
        "outputs": [
            {
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "CFOAddress",
        "outputs": [
            {
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "CMOAddress",
        "outputs": [
            {
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "getBalance",
        "outputs": [
            {
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "getCFOData",
        "outputs": [
            {
                "name": "LimitValue",
                "type": "uint256"
            },
            {
                "name": "Payed",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "getCMOData",
        "outputs": [
            {
                "name": "LimitValue",
                "type": "uint256"
            },
            {
                "name": "Payed",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    }
];

var contractInstance = web3.eth.contract(bankAbiArray).at(bankAddress);

//--------работа с оплатами--------
function bankSendTest() {
    console.log('send fund to bank start...');

    contractInstance.receive.sendTransaction(
        {
            from: wallets[0],
            value: web3.toWei(1, "finney"),
            gasPrice: 1000000000,
        },
        function (e, result) {
            console.log(e, result);
        }
    );
    console.log('send fund to bank end');
}

function getBalance()
{
    contractInstance.getBalance(
        function (e, result) {
            if (result == null) {
                console.log('------- getBalance result= error-----');
                return;
            }

            console.log('------- getBalance result -----');
            console.log('Balance=', result.toString());
        }
    );
}

function transferFunds()
{
    console.log('------- TransferFunds begins -----');
    contractInstance.transferFunds(
        function (e, result) {
            console.log('------- TransferFunds result -----');
            console.log(e, result);
        }
    );
}
//--------/работа с оплатами--------


//--------работа с СМО--------
function getCMOAddress()
{
    contractInstance.CMOAddress(
        function (e, result) {
            if (result == null) {
                console.log('------- CMOAddress result= error-----');
                return;
            }

            console.log('------- CMOAddress result -----');
            console.log('CMOAddress=', result.toString());
        }
    );
}

function setCMOAddress() {
    console.log('setCMOAddress start...');

    var newaddr = wallets[1];
    var newLimit = web3.toWei(1, "finney");

    contractInstance.setCMO(
        newaddr, newLimit,
        {
            from: wallets[0],
            gasPrice: 1000000000
        }
        ,function (e, result) {
            console.log(e, result);
        }
    );
    console.log('setCMOAddress end');
}

function getCMOData()
{
    console.log('getCMOData start...');

    contractInstance.getCMOData(
        function (e, result) {
            if (result == null) {
                console.log('------- getCMOData error-----');
                return;
            }
            console.log('------- getCMOData result -----');
            console.log('LimitValue=', result[0].toString());
            console.log('Payed=', result[1].toString());
        }
    );
}
//--------/работа с СМО--------

//--------работа с СМО--------
function getCFOAddress() {
    contractInstance.CFOAddress(
        function (e, result) {
            if (result == null) {
                console.log('------- CFOAddress result= error-----');
                return;
            }

            console.log('------- CFOAddress result -----');
            console.log('CFOAddress=', result.toString());
        }
    );
}

function setCFOAddress() {
    console.log('setCFOAddress start...');

    var newaddr = wallets[2];
    var newLimit = web3.toWei(1, "finney");

    contractInstance.setCFO(
        newaddr, newLimit,
        {
            from: wallets[0],
            gasPrice: 1000000000
        }
        , function (e, result) {
            console.log(e, result);
        }
    );
    console.log('setCFOAddress end');
}

function getCFOData() {
    console.log('getCFOData start...');

    contractInstance.getCFOData(
        function (e, result) {
            if (result == null) {
                console.log('------- getCMOData error-----');
                return;
            }
            console.log('------- getCMOData result -----');
            console.log('LimitValue=', result[0].toString());
            console.log('Payed=', result[1].toString());
        }
    );
}
//--------/работа с СМО--------

function canTransfer()
{
    contractInstance.canTransfer(
        function (e, result) {
            if (result == null) {
                console.log('------- canTransfer result= error-----');
                return;
            }

            console.log('------- canTransfer result -----');
            console.log('canTransfer=', result.toString());
        }
    );
}

//--------работа с адресом профита--------
//setProfitAddress
//readProfitAddress
//--------/работа с адресом профита--------
