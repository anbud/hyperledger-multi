#!/bin/bash

# Exit on first error
set -e
# Grab the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo
# check that the composer command exists at a version >v0.14
if hash composer 2>/dev/null; then
    composer --version | awk -F. '{if ($2<15) exit 1}'
    if [ $? -eq 1 ]; then
        echo 'Sorry, Use createConnectionProfile for versions before v0.15.0' 
        exit 1
    else
        echo Using composer-cli at $(composer --version)
    fi
else
    echo 'Need to have composer-cli installed at v0.15 or greater'
    exit 1
fi
# need to get the certificate 

cat << EOF > /tmp/.connection.json
{
    "name": "hlfv1",
    "type": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.vlf.zx.rs:7050" }
    ],
    "ca": { 
        "url": "http://ca.vlf.zx.rs:7054", 
        "name": "ca.vlf.zx.rs"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.vlf.zx.rs:7051",
            "eventURL": "grpc://peer0.vlf.zx.rs:7053"
        }, {
            "requestURL": "grpc://peer1.vlf.zx.rs:8051",
            "eventURL": "grpc://peer1.vlf.zx.rs:8053"
        }, {
            "requestURL": "grpc://peer2.vlf.zx.rs:9051",
            "eventURL": "grpc://peer2.vlf.zx.rs:9053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "VLFMSP",
    "timeout": 300
}
EOF

PRIVATE_KEY="${DIR}"/composer/crypto-config/peerOrganizations/vlf.zx.rs/users/Admin@vlf.zx.rs/msp/keystore/0b2764e3a332e7fe3d354d9d7aee7dbd206c9ff57897e0f99231788d4a161191_sk
CERT="${DIR}"/composer/crypto-config/peerOrganizations/vlf.zx.rs/users/Admin@vlf.zx.rs/msp/signcerts/Admin@vlf.zx.rs-cert.pem

if composer card list -n PeerAdmin@hlfv1 > /dev/null; then
    composer card delete -n PeerAdmin@hlfv1
fi
composer card create -p /tmp/.connection.json -u PeerAdmin -c "${CERT}" -k "${PRIVATE_KEY}" -r PeerAdmin -r ChannelAdmin --file /tmp/PeerAdmin@hlfv1.card
composer card import --file /tmp/PeerAdmin@hlfv1.card 

rm -rf /tmp/.connection.json

echo "Hyperledger Composer PeerAdmin card has been imported"
composer card list

