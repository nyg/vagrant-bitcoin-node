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

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT
cd "${WORK_DIR}"

# Download bitcoin-core, checksum and signatures
curl -fO "${BITCOIN_URL}/${BIN_PATH}"
curl -fO "${BITCOIN_URL}/${CHECKSUM_PATH}"
curl -fO "${BITCOIN_URL}/${SIGNATURE_PATH}"

# Verify bitcoin hash
sha256sum --ignore-missing --check "${CHECKSUM_PATH}"

# Import dev signatures
git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*

# Verify signatures – require at least one valid GPG signature
# GOODSIG excludes revoked and expired keys, unlike the "Good signature" text
GOOD_SIGS=$(gpg --status-fd 1 --verify "${SIGNATURE_PATH}" "${CHECKSUM_PATH}" | grep -c '^\[GNUPG:\] GOODSIG ' || true)
if [ "${GOOD_SIGS}" -lt 1 ]; then
    echo "ERROR: No valid GPG signatures found for ${CHECKSUM_PATH}" >&2
    exit 1
fi

# Extract and install bitcoin-core
tar -xzf "${BIN_PATH}"
sudo install -m 0755 -o root -g root "bitcoin-${BITCOIN_VERSION}"/bin/bitcoin* /usr/local/bin/

# Create bitcoin system user
id -u bitcoin >/dev/null 2>&1 || sudo useradd -r -M -U -s /usr/sbin/nologin -c "Bitcoin node user" bitcoin

# Copy bitcoind.service
sudo install -m 0644 /vagrant/bitcoind.service /etc/systemd/system/bitcoind.service

# Copy bitcoin.conf with restrictive permissions
sudo install -d -m 0710 -o root -g bitcoin /etc/bitcoin
sudo install -m 0640 -o root -g bitcoin /vagrant/bitcoin.conf /etc/bitcoin/bitcoin.conf

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment "SSH"
sudo ufw allow 8333/tcp comment "Bitcoin P2P"
sudo ufw --force enable

# Enable and start bitcoind service
sudo systemctl daemon-reload
sudo systemctl enable --now bitcoind
