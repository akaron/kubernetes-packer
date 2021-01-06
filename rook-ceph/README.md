These yaml files are modified from https://time.geekbang.org/column/article/41217 (login required),
which is basically from https://github.com/oracle/kubernetes-website/tree/master/docs/tasks/run-application .

```
kubectl apply -f configmap.yml -f service.yml
kubectl apply -f mysql-statefulset.yml
```

Wait until the pods are ready, then
```
sh insert_to_db.sh
```

It will insert file into the DB. To read from DB.
```
sh read_from_db.sh
```
