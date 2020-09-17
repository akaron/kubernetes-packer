See `./README.md` for more detail.
Assume the k8s cluster is ready.

```
vagrant ssh master1
cd /vagrant/k8s
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.35.0/deploy/static/provider/baremetal/deploy.yaml
kubectl edit svc ingress-nginx-controller -n ingress-nginx
```
In `kubectl edit`, set the value of the `externalTrafficPolicy` field of the
`ingress-nginx-controller` service spec to `Local`.  Save the file to continue.

```
# certificate
sh ./gen_cert.sh

# deploy prometheus and grafana
kubectl create -f /vagrant/k8s/prometheus-pvc.yml
helm install prometheus prometheus-community/prometheus -f /vagrant/k8s/prometheus-values.yml
kubectl create -f /vagrant/k8s/grafana-configmaps.yml
kubectl create -f /vagrant/k8s/grafana-deployment.yml

# port-forwatding
export HTTPS_NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[1].nodePort}")
socat TCP4-LISTEN:9091,fork TCP4:localhost:$HTTPS_NODEPORT &
```

Wait a bit until these pods are ready.

# update /etc/hosts in host machine
Add the app hostnames to `/etc/hosts` of host machine. The lines may look like:

```
172.28.128.3  prometheus.localk8s
172.28.128.3  grafana.localk8s
```

Replace the ip with the address of guest machine. This may help:
```
ifconfig | grep -A5 $(grep -A1 ethernets /etc/netplan/50-vagrant.yaml |head -n2 | tail -n1)|grep 'inet '|awk '{print $2}'
```


# Done

Now in the browser of host machine, open https://prometheus.localk8s:9091 for prometheus
and https://grafana.localk8s:9091 for grafana.

The default username/password for grafana is `admin/admin`.
