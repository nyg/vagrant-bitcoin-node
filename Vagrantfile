Vagrant.configure("2") do |config|
    config.vm.box = "bento/debian-12"
    config.vm.hostname = "bitcoin-node"

    config.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"  # 2GB RAM
      vb.cpus = 2         # 2 CPU cores
    end

    config.vm.network "forwarded_port", guest: 8333, host: 8333 # P2P
    config.vm.network "forwarded_port", guest: 8332, host: 8332 # RPC

    config.vm.synced_folder ".", "/vagrant"

    config.vm.provision "shell", path: "provision.sh"
end
