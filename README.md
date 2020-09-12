For test only.

The purpose is to use Vagrant and ansible to deploy a two node k8s cluster in
local machine. The k8s cluster will have Prometheus/alertmanager/grafana.

# requirements
* [Vagrant](https://vagrantup.com/)
* [ansible](https://www.ansible.com/)
* [Packer](https://packer.io)
  - in order to save some provision time
* Require at least 8 GB of memory
* Tested in Ubuntu 18.04

# Steps
* run `run packer build` to build an image for k8s cluster
* run `vagrant up` to bootstrap a k8s cluster (using ansible)
* in k8s cluster, 
    - `prometheus`: create `k8s/prometheus-pv.yaml` and then use helm chart to install
    - `grafana`: deploy `k8s/grafana-configmaps.yaml` and `k8s/grafana-deployment.yaml`

# Prepare base image
If nothing else has changed, only need to run this occasionally (the Ubuntu image
updates roughly weekly).

```
cd packer
packer build pack-k8sbase.json
vagrant box add metadata.json
cd ..
```

This will create a vagrant box `ksun/k8sbase` with essential packages for k8s
nodes.  Run `vagrant box list` to find the box.  The box is based on vagrant box
ubuntu 18.04, and the packages include kubeadm, kubectl and kubelet fixed at a
certain version.  Once you've done with these project, run `vagrant box remove
ksun/k8sbase` to remove the image.


# Bootstrap k8s cluster
In the main directory
```
vagrant up
```
It will provision two VMs:
- a `master1` with ip `192.168.50.11`
- a `worker1` with ip `192.168.50.12`

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


# Install Prometheus using helm
helm is installed during `vagrant up` with the `stable` repo configured.
Run the operations below as user `vagrant` in the `master` node.

Note: an alternative way to install prometheus: https://github.com/prometheus-operator/kube-prometheus

## Deploy Prometheus (with storage in LocalPath of VM)
```
kubectl create -f /vagrant/k8s/prometheus-pv.yaml
helm install prometheus stable/prometheus --version 11.12.0 -f /vagrant/k8s/prometheus-values.yaml
```

One can also turn off `PersistentStorage` in `prometheus-values.yaml` and don't
deploy the pv/pvc. The default values can be found in
https://github.com/helm/charts/blob/master/stable/prometheus/values.yaml . The
persistent volume is in `/data/prometheus-data` of node `worker1`. Note that there
are problems to use the synced folder `/vagrant` (if shared by NFS, there's file
lock issue; if shared type is `Virtualbox`, there's `mmap` issue?)

### Exposing Prometheus port
To access to the Prometheus from host machine, one way is:
```
export POD_NAME=$(kubectl get pods --namespace default -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 9090 &
socat TCP4-LISTEN:9091,fork TCP4:localhost:9090 &
```

Or, skip this step and use Grafana instead.

Or, use reverse proxy (in the VM) like Caddy or nginx. This may be helpful if
there are more than one port need to be forwarded.



# Install Grafana
```
kubectl create -f /vagrant/k8s/grafana-configmaps.yaml
kubectl create -f /vagrant/k8s/grafana-deployment.yaml
```

In the host machine, open in browser: `http://localhost:3000`.  The default
user/password is `admin/admin`.  The Prometheus data-source and a simple dashboard
should be ready.


# Clean up
In the host machine, same folder as the `Vagrantfile`, run `vagrant destroy`.
And `vagrant box remove ksun/k8sbase` if also want to remove the image.
