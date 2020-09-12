# purpose
Try nginx-ingress controller in local k8s (vagrant) cluster, with TLS/HTTPS enabled.

In end of this demo, the host machine can access to the grafana service via https.
Assume prometheus and grafana are deployed in the cluster as shown in `../README.md`.

I use the [ingress-nginx-conteoller](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#over-a-nodeport-service).
It does not require a Load Balancer, just use the `NodePort` method, i.e,
host browser -> NodePort -> app, where the NodePort is in every node.


# Deploy the ingress-nginx-controller
Once the k8s cluster is ready, install the ingress-nginx controller via

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.35.0/deploy/static/provider/baremetal/deploy.yaml
```

Need to set the value of the `externalTrafficPolicy` field of the `ingress-nginx-controller` Service spec to `Local`.
That is,
```
kubectl edit svc ingress-nginx-controller -n ingress-nginx
```
Then find the line `externalTrafficPolicy`, change to `Local`, then save the file.


# Deploy ingress service
Deploy the Ingress service for grafana: `kubectl create -f grafana-ingress.yml`.

In the guest machine
* create the certificate using `sh ./gen_cert.sh`
  - it create self-signed certificate and private key and put them to `kubectl secret`
* Then use `kubectl get svc -n nginx-ingress` to findout the `NodePort` for port 443
* Use `socat TCP4-LISTEN:9091,fork TCP4:localhost:30443 &`
  - choose port 9091 because it was the port selected for the port-forwarding for prometheus
    and is opened in the Vagrantfile

Note that in `grafana-ingress.yml`, I use the address `grafana.localk8s` which cannot be reolved
by the host. So need to do it manually by update the `/etc/hosts` in host
  - the hostname is the one used in the `grafana-ingress.yml` (in this case `grafana.localk8s`)
  - to find the ip address of guest VM, in guest VM:
    - find the network interface from `/etc/netplan/50-vagrant.yaml`, something like `enp0s8`
    - find the ip address of the interface, such as `ifconfig enp0s8|grep 'inet '`
    - so, in VM host, add something like this line in `/etc/hosts`:
      - `172.28.128.3  grafana.localk8s`.

Now in the browser of host machine, open https://grafana.localhost:9091 .

p.s.: can also skip the step `sh ./gen_cert.sh` and use the `NodePort` for port 80 of the
ingress controller to access the http page from the VM host.

# Clean up
Just `kubectl delete -f xxx` could work.
Remember to remove the line `grafana.localk8s` in the `/etc/hosts` of host machine.
