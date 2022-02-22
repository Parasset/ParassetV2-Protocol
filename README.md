# ParassetV2-Protocol


![image](https://github.com/Parasset/Doc/blob/main/ParassetV2.png)

## Contract Addresses

### @mainnet
#### V2.0

Contract | Address | Description
---|---|---
USDTContract | 0xdac17f958d2ee523a2206206994597c13d831ec7 | USDT-Token
NESTContract | 0x04abEdA201850aC0124161F037Efd70c74ddC74C | NEST-Token
ASETContract | 0x139cec55d1ec47493dfa25ca77c9208aba4d3c68 | ASET-Token
PTokenFactory | 0xa6F7E15e38a5ba0435E5af06326108204cD175DA | P Asset Factory Contract
PUSD | 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0 | PUSD-Token
PETH | 0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD | PETH-Token
NestQuery | 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A | NEST Oracle
NTokenController | 0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62 | NTokenController
PUSDMorPool | 0x505eFcC134552e34ec67633D1254704B09584227 | Mortgage-PUSD pool contract
PETHMorPool | 0x9a5C88aC0F209F284E35b4306710fEf83b8f9723 | Mortgage-PETH pool contract
PUSDInsPool | 0x79025438C04Ae6A683Bcc7f7c51a01Eb4C2DDabA | Insurance-USD pool contract
PETHInsPool | 0x0bd32fFC80d5B98E403985D4446AE3BA67528C2e | Insurance-ETH pool contract
StakingMiningPool | 0xbA01258Eb8e133EACE55F5f6ec76907ADdf7797f | Staking contract
PriceController | 0x54397e5869323aA28CC4aA76F5E5f21ef39BC575 | Price call contract
Governance | 0x175d282Bc8249a3b92682365118f693380cA31F4 | Governance contract

#### MortgagePool
Parameter | Value
---|---
Nest k value | 1.33
ETH k value | 1.2
Nest r0 | 0.04
ETH r0 | 0.04
Nest maxRate | 40%
ETH maxRate | 70%
Nest settlement Rate | 90%
ETH settlement Rate | 90%

#### InsurancePool
Parameter | Value
---|---
Insurance redemption cycle | 2 days
Waiting time for redemption | 7 days
Initial net value | 1
Exchange rate | 4‰

### 2021-08-05@rinkeby
Name | Address | Description
---|---|---
USDTContract | 0x813369c81AfdB2C84fC5eAAA38D0a64B34BaE582 | USDT-Token
NESTContract | 0x2Eb7850D7e14d3E359ce71B5eBbb03BbE732d6DD | NEST-Token
HBTCContract | 0x8eF7Eec35b064af3b38790Cd0Afd3CF2FF5203A4 | HBTC-Token
ASETContract | 0xBA00239Dc53282207e2101CE78c70ca9E0592b57 | ASET-Token
PTokenFactory | 0xdae16494Bf95085Efac4aaF238cC3d6eFd23C7A5 | PToken工厂合约
PUSD | 0xD51e8b129834F3Ae6855dd947f25726572862135 | PUSD-Token
PETH | 0x74E1cCEEB67bF8d56D7c28D5bB0cE388DF46e509 | PETH-Token
PBTC | 0x4A3d5e6338A15A778eC342Ee007037911a4DdF52 | PBTC-Token
NestQuery | 0x4b4065a5d2443CbA45a0ebd324113E3775825442 | Nest价格合约
NestQuery2 | 0x2F768141145053E73AEf80dde50828C87709023f | Nest价格合约2，兼容NEST4
NTokenController | 0x65D9254A562a417Ef236e430C79D7A49fdC0851b | NestNtoken合约
PUSDMorPool(Abandoned) | 0x01Ac6EcCe9270Be2908d65db40554A88ca40c354 | PUSD抵押池合约
PETHMorPool(Abandoned) | 0x54db7485E7F1e2314aBe0D9A0322A2b2f0fDBF86 | PETH抵押池合约
PUSDMorPool | 0xE6eda6C6E149A887c516066CEdfa8D7fa429Cd1b | PUSD抵押池合约
PETHMorPool | 0x95e5592C76Dd8De5301e65fda3E4D78e1bc4e018 | PETH抵押池合约
PUSDInsPool | 0x42B753b2D2409CA6C0C5B6d300Cfa85094e730a4 | PUSD保险池合约
PETHInsPool | 0x7a5b47F79424dB6A161c65df49F906e9c5BE9A02 | PETH保险池合约
PBTCInsPool | 0xdda6020268b5A8AAdE743c601c98D247c9F3e06A | PBTC保险池合约
StakingMiningPool | 0x544716F2a97112e8F50824F528c6651238c8FBf3 | 锁仓挖矿合约
PriceController | 0xB32E590D443081d94Da62C06E057CD4C30D94084 | 价格控制合约
PriceController2 | 0xe57157fD65c05B96b05a078a597649aA1DdC9fC1 | 价格控制合约2
Governance | 0xFfA0a9E299419acCf0b467017409BB3F6Bc25dEF | Governance contract

### 2021-07-28@rinkeby
Name | Address | Description
---|---|---
USDTContract | 0xEE93b12b748dd19ac27A8669dC93f99Fa5d0097a | USDT-Token
NESTContract | 0x8d6b97c482ecC00D83979dac4A703Dbff04FD84F | NEST-Token
ASETContract | 0x2E699Af89Fac54c7AAA8615B1C6Ef6A562D04a30 | ASET-Token
PTokenFactory | 0x45A0b538f5cd2A21Df069c8EC32516a5A296Ca7c | PToken工厂合约
PUSD | 0x0A024898EAC4FFDbA9d1eF3C50063E1b544147C8 | PUSD-Token
PETH | 0x0E08A19F4e9A7077334966305FB23755943b9D30 | PETH-Token
NestQuery | 0xF1b139C867Ce8C82E253F78F8c333Baff536f2f9 | Nest价格合约
NTokenController | 0x1E7E4983b386a714dbDF77dca99f3A5e33d31CF9 | NestNtoken合约
PUSDMorPool | 0xF9A4E0a9735ad21f5AB4B0C72883DaD30d2F62b6 | PUSD抵押池合约
PETHMorPool | 0x6195277068b0aC31419ab64D7b930F74033e1AB2 | PETH抵押池合约
PUSDInsPool | 0x62AdBa6A7C84bE7c3d21606d35aDbeB30d06DB8f | PUSD保险池合约
PETHInsPool | 0x0b7F0ca89354D42e26511E778A67FAA019BebE8b | PETH保险池合约
StakingMiningPool | 0x861633AdD32f4bB8B3D283C7a6323D46518E4C18 | 锁仓挖矿合约
PriceController | 0xe3d0Ed3214998202f6F0c0769955bA520C56feD3 | 价格控制合约

### 2021-07-07@rinkeby
Name | Address | Description
---|---|---
USDTContract | 0x3b9c324b529b900519d79497Aa18D9cb2728d88F | USDT-Token
NESTContract | 0x123c1A3430Fc20BF521EcD6A1B0910323C61F18F | NEST-Token
ASETContract | 0xc0c57D935320978Ce7Ab8AFf6A5b2a50CD011256 | ASET-Token
PTokenFactory | 0xa02B382833546CdaC126a0f96299E124c38E3B37 | PToken工厂合约
PUSD | 0x6fd00A9b0cA9e46729CaCC602aee73BBc63dd445 | PUSD-Token
PETH | 0xC480aFA97B1e9ad458Ef8A8D33C5481615475683 | PETH-Token
NestQuery | 0xA3b6BDbE1B30223d974C8A623b3F5e247b642008 | Nest价格合约
NTokenController | 0x3C7001C96933C0d551aa154E1dd6D823034ee9B8 | NestNtoken合约
PUSDMorPool | 0x86724C9BAD71a1CbB0aA276a1a0E05Cc7FC23Ce6 | PUSD抵押池合约
PETHMorPool | 0xf596f35aA0FE5B85dBFbAB544580DBaDB144282b | PETH抵押池合约
PUSDInsPool | 0x94895a98e0ed9e83741a257ce2Aa05240eB06756 | PUSD保险池合约
PETHInsPool | 0x08c54E500BD89D4Ac1b0c6F2D6d06d737d33a1E1 | PETH保险池合约
StakingMiningPool | 0x863731c64e6CF1983983f162836925A64aab375F | 锁仓挖矿合约
PriceController | 0xE82dA93F74e931FFE50B0e256874895cEdd2f647 | 价格控制合约
