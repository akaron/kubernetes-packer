# purpose

Here assume prometheus is already deployed in the local k8s cluster as shown in `../README.md`.

Now I want to access prometheus (and grafana) through TLS/HTTPS in this local k8s cluster
deployed by vagrant. Using a reverse proxy is probably an easy way to achieve this.

Here I use the [ingress-nginx-controller](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#over-a-nodeport-service)
for `baremetal` using `NodePort` method. It does not require a Load Balancer (physical or
software), just use the `NodePort` method, i.e, `host browser` -> `NodePort` -> `ingress`
-> `app`, where the `NodePort` exists in every node.

Once done, I can open `https://prometheus.localk8s:9091` to access to prometheus.

It's similar to deploy to cloud providers such as
[aws](https://kubernetes.github.io/ingress-nginx/deploy/#aws). But first test in local
since it does not cost money.

# Steps
## Deploy the ingress-nginx-controller
Once the k8s cluster is ready, install the ingress-nginx controller via (in the **guest**
machine)

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.35.0/deploy/static/provider/baremetal/deploy.yaml
```

Then need to update a value by:
```
kubectl edit svc ingress-nginx-controller -n ingress-nginx
```
set the value of the `externalTrafficPolicy` field of the `ingress-nginx-controller` Service spec to `Local`.


## prepare certificates
In the **guest** (the VM)
* create the certificate using `sh ./gen_cert.sh`
  - it create self-signed certificate and private key and put them to `kubectl secret`
* Then use `kubectl get svc -n nginx-ingress` to findout the `NodePort` for port 443
* Use `socat TCP4-LISTEN:9091,fork TCP4:localhost:30443 &`
  - replace `30443` with the port you found in previous step
  - the port `9091` was the port selected for the port-forwarding for prometheus and is
    opened to the host machine

## Deploy ingress services
Deploy Ingress services 

```
kubectl create -f prometheus-ingress.yml
kubectl create -f grafana-ingress.yml
```

The apps are served at `prometheus.localk8s` and `grafana.localk8s`, but the host cannot
resolve it. We can simply add these names to `/etc/hosts` of host machine.

To find the ip address of guest VM, in guest VM:
* find the network interface from `/etc/netplan/50-vagrant.yaml`, something like `enp0s8`
* find the ip address of the interface, such as `ifconfig enp0s8|grep 'inet '`
* so, in host, add lines to `/etc/hosts` (replace the ip address to the one you found):
  - `172.28.128.3  prometheus.localk8s`
  - `172.28.128.3  grafana.localk8s`

Now in the browser of host machine, open https://prometheus.localk8s:9091 .
Because it's self-signed certificate, in modern browsers there should have warnings, which
is safe to ignore.

p.s.: can also skip the step `sh ./gen_cert.sh` and use the `NodePort` for port 80 of the
ingress controller to access the http page from the VM host.

# Clean up
Just `kubectl delete -f xxx` could work.
Remember to remove the lines `prometheus.localk8s` and `grafana.localk8s` in the `/etc/hosts` of host machine.
