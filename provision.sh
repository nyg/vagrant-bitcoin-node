#!/usr/bin/env bash

set -euo pipefail

# Install dependencies
sudo apt-get update
sudo apt-get install -y curl tar gnupg git ufw

ARCH=x86_64
PLATFORM=linux-gnu
BITCOIN_VERSION=$(curl -s https://bitcoincore.org/en/download/ | grep -oP '(?<=Latest version: )[0-9.]+(?= )')

BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}"
BIN_PATH="bitcoin-${BITCOIN_VERSION}-${ARCH}-${PLATFORM}.tar.gz"
CHECKSUM_PATH=SHA256SUMS
SIGNATURE_PATH=SHA256SUMS.asc

# Download bitcoin-core, checksum and signatures
curl -O "${BITCOIN_URL}/${BIN_PATH}"
curl -O "${BITCOIN_URL}/${CHECKSUM_PATH}"
curl -O "${BITCOIN_URL}/${SIGNATURE_PATH}"

# Verify bitcoin hash
sha256sum --ignore-missing --check "${CHECKSUM_PATH}"

# Import dev signatures
git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
rm -rf guix.sigs

# Verify signatures – require at least one valid GPG signature
GOOD_SIGS=$(gpg --verify "${SIGNATURE_PATH}" 2>&1 | grep -c "^gpg: Good signature" || true)
if [ "${GOOD_SIGS}" -lt 1 ]; then
    echo "ERROR: No valid GPG signatures found for ${CHECKSUM_PATH}" >&2
    exit 1
fi

# Extract and install bitcoin-core
tar -xzf "${BIN_PATH}" -C /tmp
rm -f "${BIN_PATH}" "${CHECKSUM_PATH}" "${SIGNATURE_PATH}"
sudo install -m 0755 -o root -g root /tmp/bitcoin-"${BITCOIN_VERSION}"/bin/bitcoin* /usr/local/bin/
rm -rf /tmp/bitcoin-"${BITCOIN_VERSION}"

# Create bitcoin system user
sudo useradd -r -M -U -s /usr/sbin/nologin -c "Bitcoin node user" bitcoin

# Copy bitcoind.service
sudo cp /vagrant/bitcoind.service /etc/systemd/system/
sudo chmod 0644 /etc/systemd/system/bitcoind.service

# Copy bitcoin.conf with restrictive permissions
sudo mkdir -p /etc/bitcoin
sudo cp /vagrant/bitcoin.conf /etc/bitcoin/
sudo chmod 0640 /etc/bitcoin/bitcoin.conf
sudo chown -R bitcoin:bitcoin /etc/bitcoin

# Create log directory
sudo mkdir -p /var/log/bitcoin
sudo chown bitcoin:bitcoin /var/log/bitcoin
sudo chmod 0750 /var/log/bitcoin

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment "SSH"
sudo ufw allow 8333/tcp comment "Bitcoin P2P"
sudo ufw --force enable

# Enable and start bitcoind service
sudo systemctl daemon-reload
sudo systemctl enable --now bitcoind
