## 抵押池

### 查询

#### 计算抵押率

```
    /// @dev Calculate the mortgage rate
    /// @param mortgageAssets Amount of mortgaged assets
    /// @param parassetAssets Amount of debt
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param pTokenPrice PToken price(1 ETH = ? pToken)
    /// @return mortgage rate
    function getMortgageRate(
        uint256 mortgageAssets,
        uint256 parassetAssets, 
        uint256 tokenPrice, 
        uint256 pTokenPrice
    ) public pure returns(uint88)
```
参数 | 描述
---|---
mortgageAssets | 抵押资产数量
parassetAssets | 债仓数量
tokenPrice | 抵押资产相对于ETH的价格数量
pTokenPrice | 债务资产相对于ETH的价格数量

返回值 | 描述
---|---
- | 抵押率

- 如果标的资产不为18位精度，从nest预言机获取的价格数据需要做精度转换。如USDT(6)->PUSD(18)。

#### 债仓实时数据

```
    /// @dev Get real-time data of the current debt warehouse
    /// @param mortgageToken Mortgage asset addresss
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param uTokenPrice Underlying asset price(1 ETH = ? Underlying asset)
    /// @param maxRateNum Maximum mortgage rate
    /// @param owner Debt owner
    /// @return fee Stability fee
    /// @return mortgageRate Real-time mortgage rate(Including stability fee)
    /// @return maxSubM The maximum amount of mortgage assets can be reduced
    /// @return maxAddP Maximum number of coins that can be added
    function getInfoRealTime(
        address mortgageToken,
        uint256 tokenPrice, 
        uint256 uTokenPrice,
        uint88 maxRateNum,
        address owner
    ) public view returns(
        uint256 fee, 
        uint256 mortgageRate, 
        uint256 maxSubM, 
        uint256 maxAddP
    ) 
```

参数 | 描述
---|---
mortgageToken | 抵押资产地址
tokenPrice | 抵押资产相对于ETH的价格数量
uTokenPrice | 标的资产相对于ETH的价格数量（将从nest获取的数据直接传入，不需要做精度转换）
maxRateNum | 最大抵押率限制
owner | 债仓所有人地址

返回值 | 描述
---|---
fee | 手续费（稳定费）
mortgageRate | 债仓抵押率
maxSubM | 最大可减少的抵押资产数量
maxAddP | 最大可增加的债务数量（铸币）




#### 查询债仓数据

```
    /// @dev View debt warehouse data
    /// @param mortgageToken mortgage asset address
    /// @param owner debt owner
    /// @return mortgageAssets amount of mortgaged assets
    /// @return parassetAssets amount of debt(Ptoken,Stability fee not included)
    /// @return blockHeight the block height of the last operation
    /// @return rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @return created is it created
    function getLedger(
        address mortgageToken,
        address owner
    ) public view returns(
        uint256 mortgageAssets, 
        uint256 parassetAssets, 
        uint160 blockHeight,
        uint88 rate,
        bool created
    )
```

参数 | 描述
---|---
mortgageToken | 抵押资产地址
owner | 债仓所有人地址

返回值 | 描述
---|---
mortgageAssets | 抵押资产数量
parassetAssets | 债务数量
blockHeight | 上次操作的区块高度
rate | 上次操作后的抵押率(不是实时的抵押率)
created | 是否已创建债仓

- rate返回值除1000，71200/1000=71.2%




### 交易
- 除第一次操作外，对债仓操作都需要授权对应的p资产
#### 铸币

```
    /// @dev Mortgage asset casting ptoken
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    /// @param rate custom mortgage rate
    function coin(
        address mortgageToken,
        uint256 amount, 
        uint88 rate
    ) public payable whenActive nonReentrant
```

参数 | 描述
---|---
mortgageToken | 抵押资产地址
amount | 抵押资产数量
rate | 抵押率

- 抵押资产为ETH时，mortgageToken传入0x0。value=amount+0.01ETH
- 抵押资产为Token时，调用该方法前需要授权。value=0.01ETH
- rate传入参数为整数，70=70%

#### 增加抵押资产

```
    /// @dev Increase mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    function supplement(address mortgageToken, uint256 amount) public payable outOnly nonReentrant
```

参数 | 描述
---|---
mortgageToken | 抵押资产地址
amount | 抵押资产数量

- 抵押资产为ETH时，mortgageToken传入0x0。value=amount+0.01ETH
- 抵押资产为Token时，调用该方法前需要授权。value=0.01ETH

#### 减少抵押资产

```
    /// @dev Reduce mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of mortgaged assets
    function decrease(address mortgageToken, uint256 amount) public payable outOnly nonReentrant
```

参数 | 描述
---|---
mortgageToken | 抵押资产地址
amount | 抵押资产数量

- value=0.01ETH

#### 增加铸币

```
    /// @dev Increase debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of debt
    function increaseCoinage(address mortgageToken, uint256 amount) public payable whenActive nonReentrant
```

参数 | 描述
---|---
mortgageToken | 抵押资产地址
amount | 增加铸币数量

- value=0.01ETH

#### 减少铸币

```
    /// @dev Reduce debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param amount amount of debt
    function reducedCoinage(address mortgageToken, uint256 amount) public payable outOnly nonReentrant
```
参数 | 描述
---|---
mortgageToken | 抵押资产地址
amount | 减少铸币数量

- value=0.01ETH

#### 清算

```
    /// @dev Liquidation of debt
    /// @param mortgageToken mortgage asset address
    /// @param account debt owner address
    /// @param amount amount of mortgaged assets
    function liquidation(
        address mortgageToken,
        address account,
        uint256 amount
    ) public payable outOnly nonReentrant
```
参数 | 描述
---|---
mortgageToken | 抵押资产地址
account | 债仓所有人
amount | 抵押资产数量

- value=0.01ETH








