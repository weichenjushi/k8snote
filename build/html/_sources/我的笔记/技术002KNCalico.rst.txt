技术002KNCalico

-  `技术002KNCalico <>`__

   -  `Requirements <>`__

      -  `Basic <>`__
      -  `IP pool <>`__

技术002KNCalico
===============

Requirements
------------

Basic
~~~~~

Calico can run on any Kubernetes cluster which meets the following
criteria.

-  The kubelet must be configured to use CNI network plugins (e.g
   –network-plugin=cni).
-  The kube-proxy must be started in iptables proxy mode. This is the
   default as of Kubernetes v1.2.0.
-  The kube-proxy must be started without the –masquerade-all flag,
   which conflicts with Calico policy.
-  The Kubernetes NetworkPolicy API requires at least Kubernetes version
   v1.3.0.

IP pool
~~~~~~~

calico网段默认是

in Kubernetes, all three of the following arguments must be equal to, or
contain, the Calico IP pool CIDRs:

kube-apiserver: –pod-network-cidr kube-proxy: –cluster-cidr
kube-controller-manager: –cluster-cidr
