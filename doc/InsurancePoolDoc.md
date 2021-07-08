## 保险池

### 查询

#### 下一个赎回期时间点

```
    /// @dev View redemption period, next time
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTime() external view returns(uint256 startTime, uint256 endTime)
```
返回值 | 描述
---|---
startTime | 开始时间点
endTime | 结束时间点

#### 上一个赎回期时间点

```
    /// @dev View redemption period, this period
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTimeFront() external view returns(uint256 startTime, uint256 endTime)
```
返回值 | 描述
---|---
startTime | 开始时间点
endTime | 结束时间点

#### 被冻结的份额（不实时）

```
    /// @dev View frozen LP and unfreeze time
    /// @param add user address
    /// @return frozen LP
    /// @return unfreeze time
    function getFrozenIns(address add) external view returns(uint256, uint256)
```
参数 | 描述
---|---
add | 用户地址

返回值 | 描述
---|---
--- | 被冻结份额
--- | 解冻时间

#### 被冻结份额（实时）

```
    /// @dev View frozen LP and unfreeze time, real time
    /// @param add user address
    /// @return frozen LP
    function getFrozenInsInTime(address add) external view returns(uint256)
```
参数 | 描述
---|---
add | 用户地址

返回值 | 描述
---|---
--- | 被冻结份额

#### 可赎回份额（实时）

```
    /// @dev View redeemable LP, real time
    /// @param add user address
    /// @return redeemable LP
    function getRedemptionAmount(address add) external view returns (uint256)
```
参数 | 描述
---|---
add | 用户地址

返回值 | 描述
---|---
--- | 可赎回份额



### 交易

#### p资产兑换标的资产

```
    /// @dev Exchange: ptoken exchanges the underlying asset
    /// @param amount amount of ptoken
    function exchangePTokenToUnderlying(uint256 amount) public whenActive nonReentrant
```

参数 | 描述
---|---
amount | p资产数量

- 需要提前授权P资产；保险池中没有足够的标的资产则交易失败

#### 标的资产兑换p资产

```
    /// @dev Exchange: underlying asset exchanges the ptoken
    /// @param amount amount of underlying asset
    function exchangeUnderlyingToPToken(uint256 amount) public payable whenActive nonReentrant
```

参数 | 描述
---|---
amount | 标的资产数量

- 需要提前授权标的资产(除ETH);保险池中没有足够的p资产，则增发p资产并累加保险池中的负账户。

#### 认购保险份额

```
    /// @dev Subscribe for insurance
    /// @param amount amount of underlying asset
    function subscribeIns(uint256 amount) public payable whenActive nonReentrant
```

参数 | 描述
---|---
amount | 标的资产数量

- 需要提前授权标的资产(除ETH)
- 认购后保险份额会被冻结，直到赎回期才可以赎回

#### 赎回保险份额
```
    /// @dev Redemption insurance
    /// @param amount redemption LP
    function redemptionIns(uint256 amount) public redemptionOnly nonReentrant
```
参数 | 描述
---|---
amount | 赎回份额

- 优先赎回标的资产，标的资产不足则赎回p资产
- 只能在赎回期进行赎回操作