#!/usr/bin/env sh

set -e

# Install dependencies
sudo apt update
sudo apt install -y curl tar gnupg git

ARCH=x86_64
PLATFORM=linux-gnu
BITCOIN_VERSION=$(curl -s https://bitcoincore.org/en/download/ | grep -oP '(?<=Latest version: )[0-9.]+(?= )')

BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/"
BIN_PATH="bitcoin-${BITCOIN_VERSION}-${ARCH}-${PLATFORM}.tar.gz"
CHECKSUM_PATH=SHA256SUMS
SIGNATURE_PATH=SHA256SUMS.asc

# Download bitcoin-core, checksum and signatures
curl -O $BITCOIN_URL/$BIN_PATH
curl -O $BITCOIN_URL/$CHECKSUM_PATH
curl -O $BITCOIN_URL/$SIGNATURE_PATH

# Verify bitcoin hash
sha256sum --ignore-missing --check SHA256SUMS

# Import dev signatures
git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
rm -rf guix.sigs

# Verify signature
gpg --verify SHA256SUMS.asc 2>&1 | grep --color -E 'Good|Primary'

# Extract and install bitcoin-core
tar -xzf bitcoin*.tar.gz -C /tmp
rm bitcoin*.tar.gz
cp /tmp/bitcoin*/bin/bitcoin* /usr/local/bin

# Create bitcoin user
sudo useradd -r -M -U -s /usr/sbin/nologin -c "Bitcoin node user" bitcoin

# Copy bitcoind.service
sudo cp /vagrant/bitcoind.service /etc/systemd/system/

# Copy bitcoin.conf
sudo mkdir /etc/bitcoin
sudo cp /vagrant/bitcoin.conf /etc/bitcoin/
sudo chown bitcoin:bitcoin /etc/bitcoin/bitcoin.conf

# Enable and start bitcoind service
sudo systemctl daemon-reload
sudo systemctl enable --now bitcoind
