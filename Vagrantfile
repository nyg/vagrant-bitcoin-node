Vagrant.configure("2") do |config|
    config.vm.box = "bento/debian-12"
    config.vm.hostname = "bitcoin-node"

    config.vm.provider "virtualbox" do |vb|
      vb.name = "bitcoin-node"
      vb.memory = "4096"  # 4GB RAM
      vb.cpus = 2         # 2 CPU cores
    end

    # P2P port only – RPC (8332) is intentionally not forwarded for security
    config.vm.network "forwarded_port", guest: 8333, host: 8333

    config.vm.synced_folder ".", "/vagrant"

    config.vm.provision "shell", path: "provision.sh"
end
