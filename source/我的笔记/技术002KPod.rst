技术002KPod

技术002KPod
===========

-  `技术002KPod <>`__

   -  `分类 <>`__

      -  `静态Pod <>`__
      -  `普通Pod <>`__

   -  `调度 <>`__
   -  `资源 <>`__
   -  `建议配置 <>`__

      -  `最大Pod数目 <>`__

   -  `特性 <>`__

      -  `Node affinity节点亲和性 <>`__
      -  `Pod间的亲和性和反亲和性 <>`__
      -  `启动策略Always/OnFailure/Never <>`__

   -  `参考文献 <>`__

分类
----

静态Pod
~~~~~~~

有人提到static
Pod，这种其实也属于节点固定，但这种Pod局限很大，比如：不能挂载configmaps和secrets等，这个由Admission
Controllers控制。

普通Pod
~~~~~~~

调度
----

-  已被调度的回调：

已被调度的pod根据FilterFunc中定义的逻辑过滤，nodeName不为空，返回true时，将会走Handler中定义的AddFunc、UpdateFunc、DeleteFunc，这个其实最终不会加入到podQueue中，但需要加入到本地缓存中，因为调度器会维护一份节点上pod列表的缓存。

-  未被调度的回调：

未被调度的pod根据FilterFunc中定义的逻辑过滤，nodeName为空且pod的SchedulerName和该调度器的名称一致时返回true；返回true时，将会走Handler中定义的AddFunc、UpdateFunc、DeleteFunc，这个最终会加入到podQueue中，kube-scheduler开始调度

资源
----

第一阶段由运行在master上的AttachDetachController负责，为这个PV完成
Attach 操作，为宿主机挂载远程磁盘；

第二阶段是运行在每个节点上kubelet组件的内部，把第一步attach的远程磁盘
mount
到宿主机目录。这个控制循环叫VolumeManagerReconciler，运行在独立的Goroutine，不会阻塞kubelet主控制循环。

完成这两步，PV对应的“持久化
Volume”就准备好了，POD可以正常启动，将“持久化
Volume”挂载在容器内指定的路径。

建议配置
--------

最大Pod数目
~~~~~~~~~~~

一个node允许最大Pod数是110，这是因为node
health机制会遍历这个node上的所有容器的状态

静态 pod指在特定的节点上直接通过
kubelet守护进程进行管理，APIServer无法管理。它没有跟任何的控制器进行关联，kubelet
守护进程对它进行监控，如果崩溃了，kubelet 守护进程会重启它。Kubelet
通过APIServer为每个静态 pod 创建 镜像 pod，这些镜像 pod 对于
APIServer是可见的（即kubectl可以查询到这些Pod），但是不受APIServer控制。

特性
----

NodeSelector->Node affinity -> Pod Affinity/AntiAffinity

Node affinity节点亲和性
~~~~~~~~~~~~~~~~~~~~~~~

两种类型 requiredDuringSchedulingIgnoredDuringExecution-》“hard”
-》必须满足
preferredDuringSchedulingIgnoredDuringExecution-》“soft”-》尽量满足
pods/pod-with-node-affinity.yaml

::

   apiVersion: v1
   kind: Pod
   metadata:
     name: with-node-affinity
   spec:
     affinity:
       nodeAffinity:
         requiredDuringSchedulingIgnoredDuringExecution:
           nodeSelectorTerms:

           - matchExpressions:
             - key: kubernetes.io/e2e-az-name

               operator: In
               values:

               - e2e-az1
               - e2e-az2

         preferredDuringSchedulingIgnoredDuringExecution:

         - weight: 1

           preference:
             matchExpressions:

             - key: another-node-label-key

               operator: In
               values:

               - another-node-label-value

     containers:

     - name: with-node-affinity

       image: k8s.gcr.io/pause:2.0

Pod间的亲和性和反亲和性
~~~~~~~~~~~~~~~~~~~~~~~

*Inter-pod affinity and anti-affinity require substantial amount of
processing which can slow down scheduling in large clusters
significantly. We do not recommend using them in clusters larger than
several hundred nodes.* 在大规模集群中会降低性能，因此，不建议使用。

*Note: Pod anti-affinity requires nodes to be consistently labelled,
i.e. every node in the cluster must have an appropriate label matching
topologyKey. If some or all nodes are missing the specified topologyKey
label, it can lead to unintended behavior.*
要求每个节点中必须存在该label标签

topologyKey代表节点 label的Key，默认的标签有 kubernetes.io/hostname
failure-domain.beta.kubernetes.io/zone
failure-domain.beta.kubernetes.io/region
beta.kubernetes.io/instance-type kubernetes.io/os kubernetes.io/arch
PodAntiAffinity配置，保证该该服务的两个实例不会共存在一个节点上。

::

   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: redis-cache
   spec:
     selector:
       matchLabels:
         app: store
     replicas: 3
     template:
       metadata:
         labels:
           app: store
       spec:
         affinity:
           podAntiAffinity:
             requiredDuringSchedulingIgnoredDuringExecution:

             - labelSelector:

                 matchExpressions:

                 - key: app

                   operator: In
                   values:

                   - store

               topologyKey: "kubernetes.io/hostname"
         containers:

         - name: redis-server

           image: redis:3.2-alpine

保证web-server的每个实例不会共存在同一个节点，尽量和标签为app=store的pod共存在同一台机器上

::

   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web-server
   spec:
     selector:
       matchLabels:
         app: web-store
     replicas: 3
     template:
       metadata:
         labels:
           app: web-store
       spec:
         affinity:
           podAntiAffinity:
             requiredDuringSchedulingIgnoredDuringExecution:

             - labelSelector:

                 matchExpressions:

                 - key: app

                   operator: In
                   values:

                   - web-store

               topologyKey: "kubernetes.io/hostname"
           podAffinity:
             requiredDuringSchedulingIgnoredDuringExecution:

             - labelSelector:

                 matchExpressions:

                 - key: app

                   operator: In
                   values:

                   - store

               topologyKey: "kubernetes.io/hostname"
         containers:

         - name: web-app

           image: nginx:1.12-alpine

启动策略Always/OnFailure/Never
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Daemonset里的pod
   Template下必须有RestartPolicy，如果没指定，会默认为Always
-  另外Deployment、Statefulset的restartPolicy也必须为Always，保证pod异常退出，或者健康检查
   livenessProbe失败后由kubelet重启容器。https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment
-  Job和CronJob是运行一次的pod，restartPolicy只能为OnFailure或Never，确保容器执行完成后不再重启。https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/

参考文献
--------

`Pod调度源码分析 <https://mp.weixin.qq.com/s/UcpP4koV1tTRxfM7Vmi0Ug>`__
