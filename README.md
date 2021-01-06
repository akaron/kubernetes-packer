For test only.

The purpose is to use Vagrant and ansible to deploy a two node k8s cluster in
local machine.  Once the cluster is ready, one can follow instructions in
[./k8s/README.md](./k8s/README.md) to install Prometheus, alertmanager, and grafana.

# requirements
* [Vagrant](https://vagrantup.com/)
* [ansible](https://www.ansible.com/)
* [Packer](https://packer.io)
* at least 8 GB of memory
* Tested in Ubuntu 18.04 and Mac OS 10.15

# Steps
Need two steps two start a k8s cluster:
* **Prepare an image for master and worker** using packer
* Use `vagrant up` to bootstrap a k8s cluster (create VM using Vagrant and use
  ansible to bootstrap)

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
At this point a k8s cluster is ready.

There are examples in [Install prometheus using helm](./k8s/README.md).

## Install Rook-ceph

From https://rook.io

    Rook is an open source cloud-native storage orchestrator.

    Ceph is a highly scalable distributed storage solution for block storage,
    object storage, and shared filesystems

In other words, one can deploy Ceph cluster use Rook. Rook-ceph will find and
use the raw block devices or partitions. And one can use the k8s StorageClass
[Ceph-rbd](https://kubernetes.io/docs/concepts/storage/storage-classes/#ceph-rbd)
to provision new disks.

See `note_rook-ceph.md` in how to activate this (need to run a new Vagrant first).

# Clean up k8s cluster
Run `vagrant destroy` to destroy VMs.
Optionally, run `vagrant box remove ksun/k8sbase` to remove the image.

Run `sh ./reset_k8s.sh` to reset the k8s cluster (it will `kubeadm reset -f`
then provision a k8s cluster).  It's faster than `vagrant destroy -f; vagrant up`.
