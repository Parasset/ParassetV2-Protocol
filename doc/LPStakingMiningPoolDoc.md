## 锁仓合约
### 查询

#### 查询锁仓数量

```
    /// @dev Get the amount of locked funds
    /// @param stakingToken staking token address
    /// @param account user address
    /// @return the amount of locked staked token
    function getBalance(address stakingToken, address account) external view override returns(uint256)
```
参数 | 描述
---|---
stakingToken | 锁仓token地址
account | 用户地址

返回值 | 描述
---|---
--- | 锁仓数量

#### 查询预计获得出矿

```
    /// @dev Get the estimated number of receivables
    /// @param stakingToken staking token address
    /// @param account user address
    /// @return the estimated number of receivables
    function getAccountReward(address stakingToken, address account) external view override returns(uint256)
```
参数 | 描述
---|---
stakingToken | 锁仓token地址
account | 用户地址

返回值 | 描述
---|---
--- | 预计获得出矿


### 交易
- 阶段挖矿，挖矿结束后继续锁仓将不会出矿。等到下一个挖矿阶段才继续出矿。
- 以下任何操作都会触发收益结算。

#### 锁仓

```
    /// @dev Stake
    /// @param amount amount of stake token
    /// @param stakingToken staking token address
    function stake(uint256 amount, address stakingToken) external override nonReentrant
```

参数 | 描述
---|---
amount | 锁仓数量
stakingToken | 锁仓token地址

- 操作前需要提前授权

#### 赎回

```
    /// @dev Withdraw
    /// @param amount amount of stake token
    /// @param stakingToken staking token address
    function withdraw(uint256 amount, address stakingToken) external override nonReentrant 
```
参数 | 描述
---|---
amount | 赎回锁仓数量
stakingToken | 锁仓token地址

#### 领取收益

```
    /// @dev Receive income
    /// @param stakingToken staking token address
    function getReward(address stakingToken) external override nonReentrant
```
参数 | 描述
---|---
stakingToken | 锁仓token地址