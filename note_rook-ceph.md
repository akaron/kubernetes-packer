# What is rook-ceph?
From https://rook.io

    Rook is an open source cloud-native storage orchestrator.

    Ceph is a highly scalable distributed storage solution for block storage,
    object storage, and shared filesystems

In other words, one can deploy Ceph cluster use Rook. Rook-ceph will find and
use the raw block devices or partitions. And one can use the k8s StorageClass
[Ceph-rbd](https://kubernetes.io/docs/concepts/storage/storage-classes/#ceph-rbd)
to provision new disks.

# Steps
## Update Vagarntfile
For worker nodes to access block, need Vagrant to mount a raw block device.
This is still an [experiment feature of Vagrant](https://www.vagrantup.com/docs/experimental).

Uncomment this line near the beginning of `Vagrantfile`
```
ENV["VAGRANT_EXPERIMENTAL"]="disks"
```

And uncomment this line in the worker node configuration
```
    worker.vm.disk :disk, name: "backup", size: "12GB"
```

Then start the VMs
```
vagrant destroy -f  # if necessary
vagrant up
```

## prepare worker node
After `vagrant up`, install `lvm` and `ceph-common` in worker node(s)
```
vagrant ssh worker1
sudo apt-get install lvm2 ceph-common
sudo modprobe rbd
exit
```

## Get rook repo
```
git clone --single-branch --branch v1.5.4 https://github.com/rook/rook.git
```

## Install rook-ceph (for single node)
Install rook-ceph using the `cluster-test.yaml` (it allows no redundancy storages and
pool size is 1) from the rook repo.

```
cd rook/cluster/examples/kubernetes/ceph
kubectl apply -f crds.yaml -f common.yaml -f operator.yaml

# this step need some time
kubectl apply -f cluster-test.yaml

# Create storage class `rook-ceph-block`
kubectl apply -f csi/rbd/storageclass-test.yaml
```

Check the logs to make sure ceph-OSD found the disk `/dev/sdc` in the node `worker1`.
```
kubectl logs $(kubectl get pods -l ceph-osd-id=0 -n rook-ceph -o jsonpath='{.items[0].metadata.name}') -n rook-ceph
```

# Example deployment
See [./rook-ceph/README.md](./rook-ceph/README.md).

# Multiple nodes
In production environment, one should use multiple (at least 3) nodes and block
devices.

For test purpose, if your machine is powerful, you can to create 3 VMs (edit the
`Vagrantfile`) and deploy the `cluster.yaml` and `csi/rbd/storageclass.yaml`
instead of the `-test` versions.
