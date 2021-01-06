# -*- mode: ruby -*-
# vi: set ft=ruby :

# ENV["LC_ALL"] = "en_US.UTF-8"
# ENV["VAGRANT_EXPERIMENTAL"]="disks"

Vagrant.configure("2") do |config|
  config.vm.box = "ksun/k8sbase"
  config.vm.provider "virtualbox"
  config.vm.synced_folder ".", "/vagrant"

  config.vm.define "master1", primary: true do |master|
    master.vm.hostname = "master1"
    master.vm.network "private_network", ip: "192.168.50.11"
    master.vm.provider "virtualbox" do |v|
      v.name = "udemy_prometheus1_server"
      v.memory = "1536"
    end
    master.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision/master.yml"
    end
    # TODO?: add provisioning for helm repo add/update and then install prometheus

    # open ports for prometheus(9090), grafana(3000), alertmanager(9093)
    master.vm.network "forwarded_port", guest: 9090, host: 9090, host_ip: "127.0.0.1"
    master.vm.network "forwarded_port", guest: 9093, host: 9093, host_ip: "127.0.0.1"
  end

  config.vm.define "worker1" do |worker|
    worker.vm.hostname = "worker1"
    worker.vm.network "private_network", ip: "192.168.50.12"
    worker.vm.provider "virtualbox" do |v|
      v.name = "udemy_prometheus1_worker"
      v.memory = "2560"
    end
    # worker.vm.disk :disk, name: "backup", size: "12GB"
    worker.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision/worker.yml"
    end
    worker.vm.network "forwarded_port", guest: 30300, host: 3000, host_ip: "127.0.0.1"
  end

end
