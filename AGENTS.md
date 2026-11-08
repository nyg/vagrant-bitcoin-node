# AGENTS.md

Provisioning for a Bitcoin Core full node on aarch64 Debian 12 (a Raspberry Pi 5 in production), with a Vagrantfile to rehearse it in a local VM first. The README lists what each file does and what `provision.sh` does, step by step; keep that list in sync when the script changes.

## Rules

- `provision.sh` must work unchanged on real hardware and in the VM: it reads `bitcoind.service` and `bitcoin.conf` from its own directory, and the Vagrantfile only runs it from the `/vagrant` synced folder. Keep VM-only behaviour in the Vagrantfile.
- The script must stay safe to run again on a provisioned machine. It leaves a running `bitcoind` alone; changes to the unit or config take effect after `systemctl restart bitcoind`.
- The download is verified twice, the tarball against `SHA256SUMS` and `SHA256SUMS` against the `guix.sigs` builder keys, and the script stops without a good signature. Keep both checks.
- The firewall denies all incoming traffic except SSH (22) and P2P (8333). A rule change can lock the user out of the Pi; say so whenever you touch it.
- RPC stays on localhost (`rpcbind`, `rpcallowip`), is never forwarded by the Vagrantfile, and the wallet stays disabled.
- `bitcoin.conf` is Bitcoin Core's generated full option list. Set an option by uncommenting or editing its existing line in place, not by appending a new one.
- `bitcoind.service` is sandboxed (`Type=notify`, `ProtectSystem`, `MemoryDenyWriteExecute`, `SystemCallFilter`). A new option or syscall can stop the daemon from starting, so check `systemctl status bitcoind` and `journalctl -u bitcoind` in the VM after changing the unit.

## Testing

`vagrant up` on an arm64 host (Apple Silicon) provisions a fresh VM, and `vagrant provision` re-runs the script on it, which checks that a second run stays safe. A full sync is not needed to test: confirm the service starts and `sudo -u bitcoin bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf getblockchaininfo` answers.
