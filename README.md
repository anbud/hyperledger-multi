# Hyperledger on multiple physical machines

## Domains:
- orderer: orderer.vlf.zx.rs
- CA server: ca.vlf.zx.rs
- peer 0 (*163.172.153.65*): peer0.vlf.zx.rs
- peer 1 (*163.172.153.65*): peer1.vlf.zx.rs
- peer 2 (*46.101.239.172*): peer2.vlf.zx.rs

## Commands
(*mostly from [here](https://www.skcript.com/svr/setting-up-a-blockchain-business-network-with-hyperledger-fabric-and-composer-running-in-multiple-physical-machine/)*)


### Install docker
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
```

### Install docker composer
```
curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### Bootstrap hyperledger (current 1.0.6)
```
curl https://raw.githubusercontent.com/hyperledger/fabric/release/scripts/bootstrap.sh > bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

### Install nodejs
```
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Install build essentials
```
sudo apt-get install -y build-essential
```

### Install composer-cli
```
npm install -g composer-cli --unsafe-perm
```

### Clone this repo
```
git clone https://github.com/anbud/hyperledger-multi
```

### If something changes in crypto-config.yaml
```
cryptogen generate --config=./crypto-config.yaml
```

### If something changes in configtx.yaml
```
export FABRIC_CFG_PATH=$PWD
configtxgen -profile ComposerOrdererGenesis -outputBlock ./composer-genesis.block
configtxgen -profile ComposerChannel -outputCreateChannelTx ./composer-channel.tx -channelID composerchannel
```

## Machine-specific commands

### On machine 1
```
./teardownFabric.sh && ./startFabric.sh && ./createPeerAdminCard.sh
```

### On machine 2
```
./startFabric-Peer2.sh
```
