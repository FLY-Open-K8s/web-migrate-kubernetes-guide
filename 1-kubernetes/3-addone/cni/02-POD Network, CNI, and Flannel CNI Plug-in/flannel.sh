
#ip link show type veth
#ip link show type bridge
#bridge link show grep cni0
#kubectl get pods -o wide grep kube-node1-fl
#ip route

#Get pod info
kubectl get pods -o wide
#Get all deployments in the current name space
kubectl get services
#Call the service through cluster IP
curl http://192.168.0.30:30115
#Call the service directly through a POD
curl http://10.244.0.14:8080

#SSh to a POd
kubectl exec -it hello-world-5457b44555-57vg9 --sh


tshark -v --color -i ethe-d udp.port=8472,vxlan -f "port 8472"