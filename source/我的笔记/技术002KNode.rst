技术002KNode

技术002KNode
============

-  `技术002KNode <>`__

   -  `影响k8s集群节点数规模的因素 <>`__
   -  `集群支持的节点数目 <>`__

      -  `v1.16 - 5000 <>`__

   -  `集群的Node选择大资源配置机器还是小资源配置机器 <>`__

      -  `大资源节点 <>`__
      -  `小资源节点 <>`__

   -  `集群到底用大资源节点还是小资源节点-总结 <>`__
   -  `参考文献 <>`__

影响k8s集群节点数规模的因素
---------------------------

-  etcd

如果我们继续使用 etcd v2 的话，是无法负载 5000 节点的集群规模的。etcd v2
中的 watch 实现是一个主要障碍。在 5000
节点规模的集群中，我们每秒需要向同一个 watcher 发送至少 500 个 watch
事件，这在 v2 中是不可能的。

集群支持的节点数目
------------------

v1.16 - 5000
~~~~~~~~~~~~

At v1.16, Kubernetes supports clusters with up to 5000 nodes. More
specifically, we support configurations that meet all of the following
criteria:

前提条件：

-  No more than 5000 nodes
-  No more than 150000(15w) total pods
-  No more than 300000(30w) total containers
-  No more than 100 pods per node

集群的Node选择大资源配置机器还是小资源配置机器
----------------------------------------------

大资源节点
~~~~~~~~~~

-  优点

1 Less management overhead 降低管理成本 2 Lower costs per node
针对于裸机，每个节点更少的费用，因为资源和节点数目不是线性增加的
针对于公有云，使用大机器不会节省费用 3.Allows running resource-hungry
applications

-  缺点

1 Large number of pods per node 2 Limited replication 3 Higher blast
radius 4 Large scaling increments

小资源节点
~~~~~~~~~~

-  优点

1 Reduced blast radius 机器的资源越小，宕机的话影响的范围越小 2 Allows
high replication 将副本数打的更散一点儿，服务保障行更好

-  缺点

1 Large number of nodes But large numbers of nodes can be a challenge
for the Kubernetes control plane. 1)节点之间互相通信以节点的平方增加
2）controller manager组件挨个遍历每个节点的健康情况，增加了该组件的负担
3）etcd的负担，kubelet通过api-server watch object的变化
官方支持5009节点，实际上500个节点就有点问题了
更多的node节点就需要配置更好的master。

As you can see, for 500 worker nodes, the used master nodes have 32 and
36 CPU cores and 120 GB and 60 GB of memory, respectively.

\**So, if you intend to use a large number of small nodes, there are two
things you need to keep in mind

1.The more worker nodes you have, the more performant master nodes you
need

2.If you plan to use more than 500 nodes, you can expect to hit some
performance bottlenecks that require some effort to solve*\*

2 More system overhead

For example, imagine that all system daemons of a single node together
use 0.1 CPU cores and 0.1 GB of memory.

If you have a single node of 10 CPU cores and 10 GB of memory, then the
daemons consume 1% of your cluster’s capacity.

如果物理机10c，10G，那么daemons守护进程将会占用1/100的资源，那么1/100的资源账单将会用来运行系统进程。

On the other hand, if you have 10 nodes of 1 CPU core and 1 GB of
memory, then the daemons consume 10% of your cluster’s capacity.

Thus, in the second case, 10% of your bill is for running the system,
whereas in the first case, it’s only 1%.

3 Lower resource utilisation 4 Pod limits on small nodes

集群到底用大资源节点还是小资源节点-总结
---------------------------------------

-  根据你的应用来调整你的集群
-  集群的节点的配置多样化

参考文献
--------

`not-one-size-fits-all-how-to-size-kubernetes-clusters.pdf <https://static.sched.com/hosted_files/kccnceu18/4e/kubecon2018-not-one-size-fits-all-how-to-size-kubernetes-clusters.pdf>`__

`Building large
clusters <https://kubernetes.io/docs/setup/best-practices/cluster-large/>`__

Architecting Kubernetes clusters — choosing a worker node size
