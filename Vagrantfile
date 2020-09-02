# -*- mode: ruby -*-
# vi: set ft=ruby :

# ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure("2") do |config|
  config.vm.box = "ksun/k8sbase"
  config.vm.provider "virtualbox"

  config.vm.define "master1", primary: true do |master|
    master.vm.hostname = "master1"
    master.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: true
    master.vm.provider "virtualbox" do |v|
      v.name = "udemy_prometheus1_server"
      v.memory = "1536"
    end
    master.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision/10-master.yml"
    end
    master.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision/20-master-kubeadm-init.yaml"
    end
    # TODO?: add provisioning for helm repo add/update and then install prometheus

    # open ports for prometheus(9090), grafana(3000), alertmanager(9093)
    # note: if follow README.md, the port 9090 only listen to VM's local, so use a socat to open port 9091 to listen to all
    master.vm.network "forwarded_port", guest: 9091, host: 9091, host_ip: "127.0.0.1"
    master.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "127.0.0.1"
    master.vm.network "forwarded_port", guest: 9093, host: 9093, host_ip: "127.0.0.1"
  end

  config.vm.define "worker1" do |worker|
    worker.vm.hostname = "worker1"
    worker.vm.network "private_network", ip: "192.168.50.12", virtualbox__intnet: true
    worker.vm.provider "virtualbox" do |v|
      v.name = "udemy_prometheus1_worker"
      v.memory = "1536"
    end
    worker.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision/10-worker.yml"
    end
    worker.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision/30-worker-join-playbook.yml"
    end
  end

end
