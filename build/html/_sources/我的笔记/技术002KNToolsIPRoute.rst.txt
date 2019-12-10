技术002KNToolsIPRoute

技术002KNToolsIPRoute
=====================

[TOC

安装
----

yum install iproute

常用命令
--------

ip addr ip addr show eth0 ip link ip link show eth0 ip -s link show eth0
统计网卡的输入和输出 ip route show default via 107.170.58.1 dev eth0
metric 100 107.170.58.0/24 dev eth0 proto kernel scope link src
107.170.58.162

This shows us that the default route to the greater internet is
available through the eth0 interface and the address 107.170.58.1. We
can access this server through that interface, where our own interface
address is 107.170.58.162.

重启网卡 ip link set eth1 up ip link set eth1 down 广播 ip link set eth1
multicast on ip link set eth1 multicast off
调整最大传输数据包mtu和队列大小 ip link set eth1 mtu 1500 ip link set
eth1 txqueuelen 1000 在网卡down的状态下，修改网卡的名字和arp状态 ip link
set eth1 name eth10 ip link set eth1 arp on 添加device的地址 ip addr add
ip_address/net_prefix brd + dev interface 删除device的地址 ip addr del
ip_address/net_prefix dev interface ip rule show
