技术002KIngress

-  `技术002KIngress <>`__

   -  `Ingress <>`__

      -  `Nginx-Ingress <>`__

   -  `其他服务暴露方式 <>`__

      -  `CLUSTERIP <>`__
      -  `NODEPORT <>`__
      -  `haproxy <>`__

   -  `参考文献 <>`__

技术002KIngress
===============

Ingress
-------

一个集群可以配置多个Ingress。创建Ingress时，可以通过注解ingress.class表示那种ingress。

-  性能优化

由于NginxIngress
Controller要监听物理机上的80端口，我们最初的做法是给他配置了hosrtport，但当大量业务上线时，我们发现QPS超过500/s就会出现无法转发数据包的情况。经过排查发现，系统软中断占用的CPU特别高，hostport会使用iptables进行数据包的转发，后来将Ingress
Controller修改为hostnetwork模式，直接使用Docker的host模式，性能得到提升，QPS可以达到5k以上。

-  Nginx配置优化

Nginx
IngressController大致的工作流程是先通过监听Service、Ingress等资源的变化然后根据Service、Ingress的信息以及nginx.temple文件，将每个service对应的endpoint填入模板中生成最终的Nginx配置。但是很多情况下模板中默认的配置参数并不满足我们的需求，这时需要通过kubernetes中ConfigMap机制基于Nginx
Ingress Controller使用我们定制化的模板。

-  日志回滚

默认情况下Docker会将日志记录在系统的/var/lib/docker/container/xxxx下面的文件里，但是前端日志量是非常大的，很容易就会将系统盘写满，通过配置ConfigMap的方式，可以将日志目录改到主机上，通过配置logrotate服务可以实现日志的定时回滚、压缩等操作。

-  服务应急

当线上服务出现不可用的情况时，我们会准备一套应急的服务作为备用，一但服务出现问题，我们可以将流量切换到应急的服务上去。在k8s上，这一系列操作变得更加简单，这需再准备一套ingress规则，将生产环境的Servuce改为应急的Service，切换的时候通过kubectl
replace -f xxx.yaml 将相应的Ingress替换，即可实现服务的无感知切换。

Nginx-Ingress
~~~~~~~~~~~~~

-  nginx-ingress方案测试通过

（1）根据自己的需要创建ingress的deploy

kubectl apply -f
https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml

（2）根据自己的需要创建svc

kubectl apply -f
https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/service-nodeport.yaml

（3）参考文档3创建两个deploy，测试通过 参考文档

文档1 NGINX Ingress Controller
https://kubernetes.github.io/ingress-nginx/deploy/#prerequisite-generic-deployment-command

文档2 ingress
https://kubernetes.io/docs/concepts/services-networking/ingress/

文档3 Set up Ingress on Minikube with the NGINX Ingress Controller
https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

-  示例配置文件

   apiVersion: v1 items:

   -  apiVersion: extensions/v1beta1

      kind: Ingress metadata: annotations:
      ingress.kubernetes.io/force-ssl-redirect: “true”
      ingress.kubernetes.io/rewrite-target: /
      kubernetes.io/ingress.class: nginx creationTimestamp:
      2019-05-10T05:29:28Z generation: 1 name: audio-callback-api
      namespace: default resourceVersion: “386759969” selfLink:
      /apis/extensions/v1beta1/namespaces/default/ingresses/audio-callback-api
      uid: 94dcfb45-72e4-11e9-804a-6c92bf4758bd spec: rules:

      -  host: cl-k8s.yidianzixun.com

         http: paths:

         -  backend:

            serviceName: audio-callback-api servicePort: http path:
            /audio status: loadBalancer: ingress:

         -  {}

   -  apiVersion: extensions/v1beta1

      kind: Ingress metadata: annotations:
      ingress.kubernetes.io/grpc-backend: “true”
      ingress.kubernetes.io/proxy-body-size: 16m
      ingress.kubernetes.io/ssl-redirect: “true”
      kubernetes.io/ingress.class: nginx creationTimestamp:
      2019-03-28T02:25:53Z generation: 1 name: compete-feedback-grpc
      namespace: default resourceVersion: “386759940” selfLink:
      /apis/extensions/v1beta1/namespaces/default/ingresses/compete-feedback-grpc
      uid: cf931119-5100-11e9-9b8a-5cb9019cfa9c spec: rules:

      -  http:

         paths:

         -  backend:

            serviceName: compete-feedback servicePort: grpc path:
            /feed.FeedBack status: loadBalancer: ingress:

         -  {}

其他服务暴露方式
----------------

CLUSTERIP
~~~~~~~~~

-  ClusterIP是通过每个节点的kuber-proxy进程修改本地的iptables，使用DNAT的方式将ClusterIP转换为实际的endpoint地址。

NODEPORT
~~~~~~~~

-  NodePort是为了Kubernetes集群外部的应用方便访问kubernetes的服务而提供的一种方案，它会在每个机器上。

-  

haproxy
~~~~~~~

百分点采用的Loadbalancer负载均衡器是基于haproxy，通过watcher
Kubernetes-apiserver中service以及endpoint信息，\ **动态修改haproxy转发规则**\ 来实现的。

参考文献
--------

`K8s 工程师必懂的 10 种 Ingress
控制器 <https://mp.weixin.qq.com/s/ooPkJUgtwpdYGwpDjuyrdA>`__

你想要的百分点大规模Kubernetes集群应用实践来了
