#!/bin/bash

set -e

# FOR TESTING PURPOSES ONLY
# MAKE SURE ALL SECRETS ARE LOADED THROUGH SECURE ENV VARIABLES

# ---[ 1. Set up environment ]---
export USER=$(whoami)
export MINA_HOME="/home/$USER"
export DEBIAN_FRONTEND=noninteractive
export NIX_CONFIG="experimental-features = nix-command flakes"
export PORTABLE=1
export ROCKSDB_USE_SSE=0
export FORCE_SSE42=0
export MINA_PASSWORD="validatorpass"
export MINA_PRIVKEY_PASS="validatorpass"


# ---[ 11. Wallet setup ]---
mkdir -p ~/keys
chmod 700 ~/keys
echo "Generating wallet..."
mina advanced generate-keypair --privkey-path ~/keys/my-wallet
chmod 600 ~/keys/my-wallet

echo "Validating wallet..."
mina advanced validate-keypair --privkey-path ~/keys/my-wallet

# ---[ 12. libp2p key ]---
echo "Generating libp2p keypair..."
mina libp2p generate-keypair --privkey-path ~/keys/libp2p

# ---[ 13. Configure daemon ]---
mkdir -p ~/.mina-config
PUBKEY=$(cat ~/keys/my-wallet.pub)
cat > ~/.mina-config/daemon.json <<EOL
{
  "daemon": {
    "client-port": 1000,
    "external-port": 1001,
    "rest-port": 1002,
    "genesis-ledger-dir": "$MINA_HOME/mina/genesis_ledgers/",
    "config-directory": "$HOME/.mina-config/",
    "config-file": "$HOME/.mina-config/daemon.json",
    "block-producer-key": "$HOME/keys/my-wallet",
    "libp2p-keypair": "$HOME/keys/libp2p",
    "block-producer-password": "validatorpass",
    "block-producer-pubkey": "$PUBKEY",
    "coinbase-receiver": "$PUBKEY",
    "log-block-creation": false,
    "log-received-blocks": false,
    "log-snark-work-gossip": false,
    "log-txn-pool-gossip": false,
    "peers": ["seed-one.o1test.net", "seed-two.o1test.net"],
    "run-snark-worker": "$PUBKEY",
    "snark-worker-fee": 10,
    "snark-worker-parallelism": 1,
    "work-reassignment-wait": 420000,
    "work-selection": "seq"
  }
}
EOL

# ---[ 14. Set environment variables for keys and configurations ]---
export PUBKEY="$PUBKEY"
export CONFIG_DIR="$HOME/.mina-config/"
export DAEMON_PATH="$HOME/.mina-config/daemon.json"
export LIBP2P_PATH="$HOME/keys/libp2p"
export MINA_PASSWORD="validatorpass"
export MINA_PRIVKEY_PASS="validatorpass"

# ---[ 15. Set permissions and store wallet ]---
chmod 700 ~/keys
chmod 600 ~/keys/*
mkdir -p ~/.mina-config/wallets/store/
cp ~/keys/my-wallet ~/.mina-config/wallets/store/B62qk81cQgLDcCWQ3bvbCcjum7w6JzJPLbhEKcyK5F3CCmvYp7RbRni

# ---[ 16. Echo password env ]---
echo "MINA_PRIVKEY_PASS is set: $MINA_PRIVKEY_PASS"

# ---[ 17. Run daemon ]---
mina daemon \
  --config-file ~/.mina-config/daemon.json \
  --generate-genesis-proof true \
  --background

echo "Mina installation and configuration complete!"