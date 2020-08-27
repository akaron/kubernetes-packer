# Prepare base image
If nothing has changed, only need to run this occationally (the upstream
may update weekly).
```
cd packer
packer build pack-k8sbase.json
vagrant box add --name k8sbase output-vagrant/package.box
```
This will create a vagrant box with essential packages for k8s nodes.
The box is based on ubuntu 18.04, and the packages include kubeadm, kubectl
and kubelet fixed at a certain version.

Note that the box name `k8sbase` is used in `Vagrantfile`.


# Bootstrap k8s cluster
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
sudo su - ubuntu
kubectl get nodes -o wide
```

A couple basic verifications are:
* make sure all the pods in namespace `kube-system` are `running`:
  `kubectl get pods -n kube-system`
* check the internal networking and dns: 
  `kubectl run -it busybox --image=busybox:1.28 --rm --restart=Never -- nslookup kubernetes.default`


# Install Prometheus using helm
helm is installed during `vagrant up`. 
Run the operations below as user `ubuntu` in the `master` node.

## Start Prometheus (without storage)
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
helm install prometheus stable/prometheus --version 11.12.0 --set server.persistentVolume.enabled=false,alertmanager.persistentVolume.enabled=false
```

## Exposing prometheus port
```
export POD_NAME=$(kubectl get pods --namespace default -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 9090 &
socat TCP4-LISTEN:9091,fork TCP4:localhost:9090 &
```

# Clean up
In the host machine, same folder as the `Vagrantfile`, run `vagrant destroy`.
And `vagrant box delete k8sbase` if also want to remove the image.
