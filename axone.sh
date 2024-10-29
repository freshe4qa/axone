#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export AXONE_CHAIN_ID=axone-dentrite-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 -y

# install go
ver="1.19" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version

# download binary
cd $HOME
git clone https://github.com/axone-protocol/axoned && cd axoned
git checkout v10.0.0
make install

# config
axoned config chain-id $AXONE_CHAIN_ID
axoned config keyring-backend test

# init
axoned init $NODENAME --chain-id $AXONE_CHAIN_ID

# download genesis and addrbook
curl -L https://snapshots-testnet.nodejumper.io/axone/genesis.json > $HOME/.axoned/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/axone/addrbook.json > $HOME/.axoned/config/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.001uaxone\"|" $HOME/.axoned/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="8331463d7bc974e49eab3bd953bceed4d66f4104@65.109.117.113:28156,e5abfa9c78479a1ea35f54d7bfb1a25921b6f387@65.109.84.33:20056,7d610ad1f75857c01b45e8b6f25d73457a543611@142.132.209.236:17656,bed4fb66aa7badfc224dd6ccc4a3cc0ab214cd7d@74.220.23.137:26656,831e3417253e14e440a1cc2782d4bbfb25596873@188.40.85.207:14156,d453ea33398978c62b45b34ea6acecc4aab3a1ed@5.9.87.231:26656,adb5e004b95e6db7041e68af878cf8b8bada0ec3@141.94.143.203:55156,a77f5b85fb8969be5540acf3a8643d6a2f07c776@84.201.135.7:26656,a98484ac9cb8235bd6a65cdf7648107e3d14dab4@95.217.74.22:13656,67faf9297f4dadf10f46ebe2a45bbe55118622c6@65.108.233.28:36656,910e678dbd20955652b8a2942fd173e54d9e95c1@65.21.233.188:17656,1d4256993f1c08571c3bf4e9362246b736b12125@65.108.199.79:26103,67bd9e88011970b3ff5652b75065c8956d0693ea@37.27.184.10:26656,4662e56afcec47fc7eacca4de4a8ca382d4b97b7@65.109.92.163:2020,4569842347acc9204971c243315f1839e89b1cc7@65.108.111.226:31656,e8838b99dabdbc60d776b359f9929ecbaf7ba82f@65.109.93.58:20056,c9d8b4ea3d4b5b95cb122f9778edbb6b399f9deb@94.130.138.48:45656,809d0a8984a2c293d263931a32f6d08e4277a106@65.109.65.210:33656,c27e8cb52aa588431e39f5c8b32c30850a228b8b@5.9.116.21:20056,8e7dc1bc3c9dc2106e077e6bbd48f3790dd5c934@144.91.115.146:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.axoned/config/config.toml

# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.axoned/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.axoned/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.axoned/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.axoned/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.axoned/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.axoned/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.axoned/config/config.toml

# create service
sudo tee /etc/systemd/system/axoned.service > /dev/null << EOF
[Unit]
Description=Axone node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which axoned) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# reset
axoned tendermint unsafe-reset-all --home $HOME/.axoned --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/axone/axone_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.axoned

# start service
sudo systemctl daemon-reload
sudo systemctl enable axoned
sudo systemctl restart axoned

break
;;

"Create Wallet")
axoned keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
AXONE_WALLET_ADDRESS=$(axoned keys show $WALLET -a)
AXONE_VALOPER_ADDRESS=$(axoned keys show $WALLET --bech val -a)
echo 'export AXONE_WALLET_ADDRESS='${AXONE_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export AXONE_VALOPER_ADDRESS='${AXONE_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
axoned tx staking create-validator \
--amount=1000000uaxone \
--pubkey=$(axoned tendermint show-validator) \
--moniker=$NODENAME \
--chain-id=axone-dentrite-1 \
--commission-rate=0.10 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=wallet \
--gas-prices=0.001uaxone \
--gas-adjustment=1.5 \
--gas=300000 \
-y  
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
