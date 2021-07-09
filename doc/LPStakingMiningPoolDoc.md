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

#### 查询lp挖矿信息

```
    /// @dev Get the lock channel information
    /// @param stakingToken staking token address
    /// @return lastUpdateBlock the height of the recently operated block
    /// @return endBlock mining end block
    /// @return rewardRate mining efficiency per block
    /// @return rewardPerTokenStored receivable mine per share
    /// @return totalSupply total locked position
    function getChannelInfo(
        address stakingToken
    ) 
    external view override returns (
        uint256 lastUpdateBlock, 
        uint256 endBlock, 
        uint256 rewardRate, 
        uint256 rewardPerTokenStored, 
        uint256 totalSupply
    ) 
```

参数 | 描述
---|---
stakingToken | 锁仓token地址

返回值 | 描述
---|---
lastUpdateBlock | 最新操作区块
endBlock | 挖矿结束区块
rewardRate | 区块出矿量
rewardPerTokenStored | 每份lp分配的矿
totalSupply | 总锁仓量


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