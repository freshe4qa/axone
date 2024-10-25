<p align="center">
  <img height="100" height="auto" src="https://github.com/user-attachments/assets/8b86c4f6-b111-4f20-ae39-f474d6baa393">
</p>

# Axone Testnet — axone-dentrite-1

Official documentation:
>- [Validator setup instructions](https://docs.axone.xyz/)

Explorer:
>- [Explorer](https://testnet.axone.explorers.guru)

### Minimum Hardware Requirements
 - 4x CPUs; the faster clock speed the better
 - 8GB RAM
 - 100GB of storage (SSD or NVME)

### Recommended Hardware Requirements 
 - 8x CPUs; the faster clock speed the better
 - 16GB RAM
 - 1TB of storage (SSD or NVME)

## Set up your artela fullnode
```
wget https://raw.githubusercontent.com/freshe4qa/axone/main/axone.sh && chmod +x axone.sh && ./axone.sh
```

## Post installation

When installation is finished please load variables into system
```
source $HOME/.bash_profile
```

Synchronization status:
```
axoned status 2>&1 | jq .SyncInfo
```

### Create wallet
To create new wallet you can use command below. Don’t forget to save the mnemonic
```
axoned keys add $WALLET
```

Recover your wallet using seed phrase
```
axoned keys add $WALLET --recover
```

To get current list of wallets
```
axoned keys list
```

## Usefull commands
### Service management
Check logs
```
journalctl -fu axoned -o cat
```

Start service
```
sudo systemctl start axoned
```

Stop service
```
sudo systemctl stop axoned
```

Restart service
```
sudo systemctl restart axoned
```

### Node info
Synchronization info
```
axoned status 2>&1 | jq .SyncInfo
```

Validator info
```
axoned status 2>&1 | jq .ValidatorInfo
```

Node info
```
axoned status 2>&1 | jq .NodeInfo
```

Show node id
```
axoned tendermint show-node-id
```

### Wallet operations
List of wallets
```
axoned keys list
```

Recover wallet
```
axoned keys add $WALLET --recover
```

Delete wallet
```
axoned keys delete $WALLET
```

Get wallet balance
```
axoned query bank balances $AXONE_WALLET_ADDRESS
```

Transfer funds
```
axoned tx bank send $AXONE_WALLET_ADDRESS <TO_AXONE_WALLET_ADDRESS> 10000000uaxone
```

### Voting
```
axoned tx gov vote 1 yes --from $WALLET --chain-id=$AXONE_CHAIN_ID
```

### Staking, Delegation and Rewards
Delegate stake
```
axoned tx staking delegate $AXONE_VALOPER_ADDRESS 10000000uaxone --from=$WALLET --chain-id=$AXONE_CHAIN_ID --gas=auto
```

Redelegate stake from validator to another validator
```
axoned tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 10000000uaxone --from=$WALLET --chain-id=$AXONE_CHAIN_ID --gas=auto
```

Withdraw all rewards
```
axoned tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$AXONE_CHAIN_ID --gas=auto
```

Withdraw rewards with commision
```
axoned tx distribution withdraw-rewards $AXONE_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$AXONE_CHAIN_ID
```

Unjail validator
```
axoned tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$AXONE_CHAIN_ID \
  --gas=300000 \
  -y
```
