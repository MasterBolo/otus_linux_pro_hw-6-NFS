# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config| 
 config.vm.box = "generic/centos7" 
 config.vm.box_version = "4.3.12" 
 config.vm.provider "virtualbox" do |v| 
 v.memory = 512
 v.cpus = 2
 end 
 config.vm.define "nfss" do |nfss| 
 nfss.vm.network "private_network", ip: "192.168.56.10",  virtualbox__intnet: "net1" 
 nfss.vm.hostname = "nfss"
 nfss.vm.provision "shell", path: "nfss_script.sh" 
 end 
 config.vm.define "nfsc" do |nfsc| 
 nfsc.vm.network "private_network", ip: "192.168.56.11",  virtualbox__intnet: "net1" 
 nfsc.vm.hostname = "nfsc"
 nfsc.vm.provision "shell", path: "nfsc_script.sh" 
 end 
end 
