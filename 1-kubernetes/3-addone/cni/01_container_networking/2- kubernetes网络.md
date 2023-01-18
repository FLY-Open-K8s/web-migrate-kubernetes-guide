# 2- kubernetes网络

**容器网络的基本要求**

- IP-per-Pod，每个 Pod 都拥有一个独立 IP 地址，Pod 内所有容器共享一个网络命名空间
- 集群内所有 Pod 都在一个直接连通的扁平网络中，可通过 IP 直接访问

- - 所有容器之间无需 NAT 就可以直接互相访问
  - 所有 Node 和所有容器之间无需 NAT 就可以直接互相访问
  - 容器自己看到的 IP 跟其他容器看到的一样

- Service cluster IP 尽可在集群内部访问，外部请求需要通过 NodePort、LoadBalance 或者 Ingress 来访问

# Pod网络

# Node网络

# CNI插件

> https://github.com/containernetworking/cni/blob/main/SPEC.md

K8s在设计网络的时候，采用的准则就一点：“灵活”！那怎么才能灵活呢？那就是 K8s 自身没有实现太多跟网络相关的操作，而是制定了一个规范：

1. 有配置文件，能够提供要使用的网络插件名，以及该插件所需信息
2. 让 CRI 调用这个插件，并把容器的运行时信息，包括容器的命名空间，容器 ID 等信息传给插件
3. 不关心网络插件内部实现，只需要最后能够输出网络插件提供的 pod IP 即可

没错一共就这三点，如此简单灵活的规范就是大名鼎鼎的 CNI 规范。

# Flannel

## 工作模式

> https://www.cnblogs.com/chenqionghe/p/11718365.html
>
> https://morven.life/posts/networking-5-docker-multi-hosts/
>
> https://developer.aliyun.com/learning/roadmap/cloudnative
>
> https://time.geekbang.org/column/article/67775?utm_source=u_nav_web&utm_medium=u_nav_web&utm_term=u_nav_web

# Calico

## 策略控制(Network Policy)

> https://morven.life/posts/networking-6-k8s-summary/

# Cluster网络

# 使用 Go 从零开始实现 CNI

> https://morven.life/posts/create-your-own-cni-with-golang/