[root@master-1 7-PV]# sudo sh -c "echo 'Hello from Kubernetes PV' > /data/kubernetes/pv/nginx-vol/hello"


[root@master-1 7-PV]# kubectl get pv | grep nginx-vol
nginx-vol                                  1Gi        RWO            Delete           Available                            manual                     27s
[root@master-1 7-PV]# kubectl apply -f nginx-pvc.yaml
persistentvolumeclaim/nginx-vol created
[root@master-1 7-PV]# kubectl get pv | grep nginx-vol
nginx-vol                                  1Gi        RWO            Delete           Bound    default/nginx-vol        manual                     2m2s
[root@master-1 7-PV]# 


kubectl exec -it nginx-pvtest /bin/bash

root@nginx-pvtest:/# ll /data
bash: ll: command not found
root@nginx-pvtest:/# ls /data
hello
root@nginx-pvtest:/# cat /data/hello
Hello from Kubernetes PV
