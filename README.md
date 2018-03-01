# Hyperledger on multiple physical machines

## Domains:
- orderer: orderer.vlf.zx.rs
- CA server: ca.vlf.zx.rs
- peer 0 (*163.172.153.65*): peer0.vlf.zx.rs
- peer 1 (*163.172.153.65*): peer1.vlf.zx.rs
- peer 2 (*46.101.239.172*): peer2.vlf.zx.rs

## Starting the network
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

## Deploying chain code (*marbles02*)
### Docker
(*it doesn't work without fabric-tools docker container*)
```
docker run -d --name cli -v /:/etc/opt -t hyperledger/fabric-tools:x86_64-1.0.6
docker exec -it cli /bin/bash
```

### Setting up variables
```
export CORE_PEER_LOCALMSPID=VLFMSP
export CORE_PEER_MSPCONFIGPATH=/etc/opt/root/hyperledger-multi/composer/crypto-config/peerOrganizations/vlf.zx.rs/users/Admin@vlf.zx.rs/msp
export CORE_PEER_ADDRESS=peer2.vlf.zx.rs:9051
```

### Get the marbles02 example
```
go get github.com/hyperledger/fabric/examples/chaincode/go/marbles02
```

### Install the chaincode
```
peer chaincode install -n marbles -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/marbles02 --cafile /etc/opt/root/hyperledger-multi/composer/crypto-config/ordererOrganizations/vlf.zx.rs/orderers/orderer.vlf.zx.rs/msp/tlscacerts/tlsca.vlf.zx.rs-cert.pem -o orderer.vlf.zx.rs:7050
```

### Instantiate the chaincode 
```
peer chaincode instantiate -n marbles -v 1.0 -C composerchannel -c '{"Args":["init"]}' -P "OR ('VLFMSP.member')" --cafile /etc/opt/root/hyperledger-multi/composer/crypto-config/ordererOrganizations/vlf.zx.rs/orderers/orderer.vlf.zx.rs/msp/tlscacerts/tlsca.vlf.zx.rs-cert.pem -o orderer.vlf.zx.rs:7050
```

### Invoke sample commands
```
peer chaincode invoke -C composerchannel -n marbles -c '{"Args":["initMarble","marble1","blue","35","tom"]}' -o orderer.vlf.zx.rs:7050
peer chaincode invoke -C composerchannel -n marbles -c '{"Args":["initMarble","marble2","red","50","tom"]}' -o orderer.vlf.zx.rs:7050
peer chaincode invoke -C composerchannel -n marbles -c '{"Args":["initMarble","marble3","blue","70","tom"]}' -o orderer.vlf.zx.rs:7050
peer chaincode invoke -C composerchannel -n marbles -c '{"Args":["transferMarble","marble2","jerry"]}' -o orderer.vlf.zx.rs:7050
peer chaincode invoke -C composerchannel -n marbles -c '{"Args":["transferMarblesBasedOnColor","blue","jerry"]}' -o orderer.vlf.zx.rs:7050
peer chaincode invoke -C composerchannel -n marbles -c '{"Args":["delete","marble1"]}' -o orderer.vlf.zx.rs:7050
```

### Query the results
```
peer chaincode query -C composerchannel -n marbles -c '{"Args":["readMarble","marble1"]}' -o orderer.vlf.zx.rs:7050
```
> Error: Error endorsing query: rpc error: code = Unknown desc = chaincode error (status: 500, message: {"Error":"Marble does not exist: marble1"}) - <nil>
(*it was deleted before*)

```
peer chaincode query -C composerchannel -n marbles -c '{"Args":["getMarblesByRange","marble1","marble3"]}' -o orderer.vlf.zx.rs:7050
```
> Query Result: {"color":"red","docType":"marble","name":"marble2","owner":"jerry","size":50}

```
peer chaincode query -C composerchannel -n marbles -c '{"Args":["getHistoryForMarble","marble1"]}' -o orderer.vlf.zx.rs:7050
```

> Query Result: [{"TxId":"278155ace54ad57759215a430d6af41a78b358603ee7522906bc2c6428d18e33", "Value":{"docType":"marble","name":"marble1","color":"blue","size":35,"owner":"tom"}, "Timestamp":"2018-03-01 11:50:41.024033627 +0000 UTC", "IsDelete":"false"},{"TxId":"06366915866eeb55b11c077919f1ed5c120c523ebfa42f3519ba45ed299a049b", "Value":{"docType":"marble","name":"marble1","color":"blue","size":35,"owner":"jerry"}, "Timestamp":"2018-03-01 11:53:43.180619975 +0000 UTC", "IsDelete":"false"},{"TxId":"a446c699b614733b725c9aa792f07f115e6b1e04d940b620e476da7ba5366a8d", "Value":null, "Timestamp":"2018-03-01 11:53:48.757559613 +0000 UTC", "IsDelete":"true"}]
