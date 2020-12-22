export ANSIBLE_HOST_KEY_CHECKING=False
ansible -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory -m command -a "kubeadm reset -f" -b master1
ansible -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory -m command -a "kubeadm reset -f" -b worker1
ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory provision/master.yml
ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory provision/worker.yml
