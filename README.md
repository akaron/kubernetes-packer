# In short
```
cd packer
packer build pack-k8sbase.json
vagrant box add metadata.json
cd ..
```
Then `vagrant up` to bring up and provision VMs and `vagrant ssh` into `master1`
```
vagrant up
vagrant ssh master1
watch kubectl get nodes,pods -A -o wide
# wait a bit until nodes/pods are ready
helm install prometheus stable/prometheus --version 11.12.0 -f /vagrant/prometheus-values.yaml
export POD_NAME=$(kubectl get pods --namespace default -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 9090 &
socat TCP4-LISTEN:9091,fork TCP4:localhost:9090 &
```
Then in the browser of host machine, open `http://localhost:9091` for the prometheus.

# Prepare base image
If nothing has changed, only need to run this occationally (the upstream
may update weekly). May need to update the `version` in `metadata.json`.
```
cd packer
packer build pack-k8sbase.json
vagrant box add metadata.json
cd ..
```
This will create a vagrant box `ksun/k8sbase` with essential packages for k8s nodes.
Run `vagrant box list` to find the box.
The box is based on vagrant box ubuntu 18.04, and the packages include kubeadm, kubectl
and kubelet fixed at a certain version.

Note that the box name `ksun/k8sbase` in the json files is also used in `Vagrantfile`.


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

## Start Prometheus (without storage)
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
helm install prometheus stable/prometheus --version 11.12.0 -f /vagrant/prometheus-values.yaml
```
The default values can be found https://github.com/helm/charts/blob/master/stable/prometheus/values.yaml
Here we turn off persistent volumes, and install node exporter to master nodes.
If use `--set` from command line to turn off persistent volumes: 
`helm install prometheus stable/prometheus --version 11.12.0 --set server.persistentVolume.enabled=false,alertmanager.persistentVolume.enabled=false`

## Exposing prometheus port
```
export POD_NAME=$(kubectl get pods --namespace default -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 9090 &
socat TCP4-LISTEN:9091,fork TCP4:localhost:9090 &
```

# Clean up
In the host machine, same folder as the `Vagrantfile`, run `vagrant destroy`.
And `vagrant box delete ksun/k8sbase` if also want to remove the image.
