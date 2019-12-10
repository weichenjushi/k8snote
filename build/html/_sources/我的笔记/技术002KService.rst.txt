技术002KService

技术002KService
===============

Service转发的原理实现
---------------------

service 转发主要是 node 上的 kube-proxy 进程通过 watch apiserver 获取
service 对应的 endpoint，再写入 iptables 或 ipvs 规则来实现的; 对于
headless service，主要是通过 kube-dns 或 coredns 动态解析到不同 endpoint
ip 来实现的。实现 service
就近转发的关键点就在于如何将流量转发到跟当前节点在同一拓扑域的 endpoint
上，也就是会进行一次 endpoint 筛选，选出一部分符合当前节点拓扑域的
endpoint 进行转发。
