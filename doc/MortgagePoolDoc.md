## 抵押池

### 查询

#### 计算稳定费

```
    /// @dev Calculate the stability fee
    /// @param parassetAssets Amount of debt(Ptoken,Stability fee not included)
    /// @param blockHeight The block height of the last operation
    /// @param rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @param nowRate Current mortgage rate (not including stability fee)
    /// @param r0Value Market base interest rate
    /// @return fee
    function getFee(
        uint256 parassetAssets, 
        uint160 blockHeight,
        uint256 rate,
        uint256 nowRate,
        uint80 r0Value
    ) public view returns(uint256)
```
参数 | 描述
---|---
parassetAssets | 债仓中债务数量
blockHeight | 当前区块高度
rate | 上次操作后的抵押率
nowRate | 当前的抵押率
r0Value | 市场基础利率

返回值 | 描述
---|---
--- | 稳定费

- parassetAssets、rate调用getLedger方法获得
- r0Value调用getR0方法获得
- nowRate调用getMortgageRate方法获得

#### 获取抵押资产的r0（市场基础利率）
```
    /// @dev View the market base interest rate
    /// @return market base interest rate
    function getR0(address mortgageToken) external view returns(uint80)
```
参数 | 描述
---|---
mortgageToken | 抵押资产的地址

返回值 | 描述
---|---
--- | r0

- 每个抵押资产的r0可能不一样
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
--- | 抵押率

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

- rate返回值除1000，71200/100000=71.2%

#### 查询最大抵押率
```
    /// @dev View the maximum mortgage rate
    /// @param mortgageToken Mortgage asset address
    /// @return maximum mortgage rate
    function getMaxRate(address mortgageToken) external view returns(uint88)
```
参数 | 描述
---|---
mortgageToken | 抵押资产地址

返回值 | 描述
---|---
---|最大抵押率

- 返回数据除以100000；70000 = 70%, 40000 = 40%

#### 查询K值
```
    /// @dev View the k value
    /// @param mortgageToken Mortgage asset address
    /// @return k value
    function getK(address mortgageToken) external view returns(uint256)
```
参数 | 描述
---|---
mortgageToken | 抵押资产地址

返回值 | 描述
---|---
---|K值

- 清算抵押率=100000/K值

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
- rate：传入70000 = 70%，1 = 0.001%

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
pTokenAmountLimit | 最大支付数量，前端自行设置，可设置最大值，本次交易所支付的P资产不超过最大支付数量

- value=0.01ETH








