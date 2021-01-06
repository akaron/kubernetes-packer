For test only.

The purpose is to use Vagrant and ansible to deploy a two node k8s cluster in
local machine. Rook-ceph cloud storage can be enabled. Once the cluster is ready,
one can follow instructions in [./k8s/README.md](./k8s/README.md) to install
Prometheus, alertmanager, and grafana.


# Requirements
* [Vagrant](https://vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)
* [ansible](https://www.ansible.com/)
* [Packer](https://packer.io)
* Require at least 8 GB of memory
* Tested in Ubuntu 18.04 and Mac OS 10.15


# Steps
There are two steps:
* Prepare an vagrant box image for master and worker nodes using packer
* Use `vagrant up` to bootstrap a k8s cluster (create VM using Vagrant and use
  ansible to bootstrap)

Optionally, see [./note_rook-ceph.md](./note_rook-ceph.md) in how to activate
rook-ceph for cloud native storage. It will use a raw block disk in the VM.

More details below.


# Prepare base image
If nothing else has changed, only need to run this occasionally (the [Ubuntu
bionic64 image](https://app.vagrantup.com/ubuntu/boxes/bionic64) updates
roughly weekly).

```
cd packer
packer build pack-k8sbase.json
vagrant box add metadata.json
cd ..
```

This will create a vagrant box `ksun/k8sbase` with essential packages for k8s
nodes.  Run `vagrant box list` to find the box.  The box is based on vagrant box
ubuntu 18.04, and the packages include kubeadm, kubectl and kubelet fixed at a
certain version.

If you want to remove the image, run `vagrant box remove ksun/k8sbase`. If you
want to update the ubuntu to latest version, run `vagrant box update` to update
ubuntu image, then run `packer build` to pack a new vagrant box image.


# Bootstrap k8s cluster
Edit the `Vagrantfile` if you want (such as add more memory to the nodes. The
default is 1.5GB for master and 2.5GB for worker. With this setting, the memory
usage is at high pressure in my Macbook pro with 8GB of RAM.)

In the main directory
```
vagrant up
```
It will provision two VMs:
- a `master1` with ip `192.168.50.11`
- a `worker1` with ip `192.168.50.12`

The provision may need several minutes or more.

## verify the k8s cluster
At this point, the k8s cluster is ready. To access to the cluster need to login
to the `master1` node
```
vagrant ssh master1
kubectl get nodes -o wide
```

A couple basic verifications are:
* make sure all the pods in namespace `kube-system` are `running`:
  `kubectl get pods -n kube-system`
* check the internal networking and dns: 
  `kubectl run -it busybox --image=busybox:1.28 --rm --restart=Never -- nslookup kubernetes.default`


# Use the k8s cluster
For instance, follow ([./k8s/README.md](./k8s/README.md)) to install prometheus using helm.
If rook-ceph is enabled, see [./rook-ceph/README.md](./rook-ceph/README.md) to deploy a mysql
which utilize the storageClass.

# Clean up k8s cluster
Run `vagrant destroy` to destroy VMs.
Optionally, run `vagrant box remove ksun/k8sbase` to remove the image.

Run `sh ./reset_k8s.sh` to reset the k8s cluster (it will `kubeadm reset -f`
then provision a k8s cluster).  It's faster than `vagrant destroy -f; vagrant up`.
