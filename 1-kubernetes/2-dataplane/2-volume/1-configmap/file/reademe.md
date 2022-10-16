kubectl create configmap nginx-configmap --from-file=get.conf
kubectl apply -f nginx-configmap.yaml

kubectl apply -f nginx-configmap.yaml
kubectl apply -f nginx-pod.yaml

kubectl exec -it nginx /bin/bash

kubectl get pod -owide
curl -L http://10.244.39.20/get


kubectl edit cm/nginx-get-conf

