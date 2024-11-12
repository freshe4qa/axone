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
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.7.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.profile
source .profile

# download binary
cd $HOME && rm -rf axoned
git clone https://github.com/axone-protocol/axoned.git
cd axoned
git checkout v10.0.0
make install

# config
#axoned config chain-id $AXONE_CHAIN_ID
#axoned config keyring-backend test

# init
axoned init $NODENAME --chain-id $AXONE_CHAIN_ID

# download genesis and addrbook
curl -L https://snapshots-testnet.nodejumper.io/axone/genesis.json > $HOME/.axoned/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/axone/addrbook.json > $HOME/.axoned/config/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.001uaxone\"|" $HOME/.axoned/config/app.toml

# set peers and seeds
SEEDS="3f472746f46493309650e5a033076689996c8881@axone-testnet.rpc.kjnodes.com:13659"
PEERS="d453ea33398978c62b45b34ea6acecc4aab3a1ed@5.9.87.231:26656,8ea05a621d5fdfbda4192ae8369f289ef04c04ba@78.46.74.23:25656,0f219e851af7cd4fca087bff354dc407a76c3ce2@144.76.112.58:24656,d89568d0fda69b1951a433f5f5ff887213a41305@5.9.73.170:17656,a1da085f304cda7a6bf42d0e025ca84764aeef7f@142.132.152.46:18656,d8b4abd10feb608db9ed6dd3926dfa85eed3c498@43.131.53.203:26656,9614c853f70a0010215587a31677b99144e96507@152.228.211.19:26656,5e7747650adbed323baff71523b4cdeaf6d8a57c@77.68.82.101:26655,aa968e094c5530203232d4a1c6d20fd172bba586@135.181.79.242:26656,4569842347acc9204971c243315f1839e89b1cc7@65.108.111.226:31656,839bc9d8aea9a187b59df6f8e42a16f8e6d875a1@65.21.47.120:34656,24871048be1e61ea1df2e06ed7ed3e5cd829c92a@65.109.112.148:10096,e2eeb94a734de5d4cdca408ffb3ef675183105d5@65.109.83.40:29856,910e678dbd20955652b8a2942fd173e54d9e95c1@65.21.233.188:17656,7bcb9d1682d261f6336035ed436ba868bdace0ef@144.217.68.182:21956,582dbc3df1128a55a3ced347a6ad7e57d42e3d8c@136.243.13.36:17656,ab93659fbefaa8e5ede54b1abeaa747682aba59e@74.208.16.201:26646,e333cd668f43ff0994fb1e5aad1315061120af74@213.199.44.243:17656,a98484ac9cb8235bd6a65cdf7648107e3d14dab4@95.217.74.22:13656,cee4251c2ee5f24ed0e180dc1d3298d66ebe13e8@49.12.150.42:26736"
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
