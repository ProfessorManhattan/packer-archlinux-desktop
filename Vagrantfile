# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.ssh.insert_key = false

  config.vm.define "archlinux" do |archlinux|
    archlinux.vm.box="ProfessorManhattan/Molecule-Archlinux-20.12.01"
    archlinux.vm.hostname = "vagrant-archlinux"

    archlinux.vm.network "private_network",
       ip:"172.24.24.3",
       netmask:"255.255.255.0"

    archlinux.vm.provider "virtualbox" do |vb|
       vb.customize ["modifyvm", :id, "--vram", "256"]
    end
  end
end
