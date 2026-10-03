# vagrant-bitcoin-node

Sets up a Bitcoin Core full node on 64-bit ARM Debian 12, such as a Raspberry Pi 5, as a hardened systemd service. A Vagrantfile is included to try the whole setup in a local VM before running it on the real machine.

## What is in here

| File | Purpose |
|------|---------|
| `provision.sh` | Installs Bitcoin Core and configures the machine. Runs on any aarch64 Debian 12 system, in a VM or on real hardware. |
| `bitcoind.service` | systemd unit that runs `bitcoind` as the `bitcoin` user with sandboxing enabled. |
| `bitcoin.conf` | Node configuration, installed to `/etc/bitcoin/bitcoin.conf`. |
| `Vagrantfile` | Boots a Debian 12 VirtualBox VM (4 GB RAM, 2 CPUs) and runs `provision.sh` in it. |

## What provision.sh does

1. Installs `curl`, `gnupg`, `git` and `ufw`.
2. Downloads the latest aarch64 Bitcoin Core release from bitcoincore.org.
3. Checks the tarball against `SHA256SUMS`, then checks `SHA256SUMS` against the builder keys from [guix.sigs](https://github.com/bitcoin-core/guix.sigs). It stops unless at least one signature is good.
4. Installs the binaries to `/usr/local/bin`.
5. Creates the `bitcoin` system user.
6. Installs `bitcoind.service` and `bitcoin.conf` from the directory the script is in.
7. Enables the firewall: all incoming traffic is denied except SSH (22) and Bitcoin P2P (8333).
8. Enables and starts `bitcoind`.

The script can be run again on the same machine. It does not restart a running `bitcoind`, so run `sudo systemctl restart bitcoind` after changing the unit or the configuration.

## Run it in a VM

Requires Vagrant and VirtualBox on an arm64 host, for example an Apple Silicon Mac.

```bash
vagrant up
```

```bash
vagrant ssh
```

Port 8333 is forwarded to the host. The RPC port is not forwarded.

## Run it on a real machine

On a fresh 64-bit Debian 12 install, for example on a Raspberry Pi 5, clone this repository and run the script as root:

```bash
sudo bash provision.sh
```

Before you run it:

- The firewall only allows SSH on port 22. If your SSH server listens on another port, change the rule in `provision.sh` or you will be locked out.
- A full node needs about 860 GB in `/var/lib/bitcoind`. Set `prune` in `bitcoin.conf` if you have less.

## Using the node

```bash
systemctl status bitcoind
```

```bash
sudo -u bitcoin bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf getblockchaininfo
```

| Path | Content |
|------|---------|
| `/etc/bitcoin/bitcoin.conf` | Configuration, readable by the `bitcoin` group only |
| `/var/lib/bitcoind` | Blockchain data |
| `/var/log/bitcoin/debug.log` | Log file |

RPC listens on localhost only. The wallet is disabled.

## License

MIT
