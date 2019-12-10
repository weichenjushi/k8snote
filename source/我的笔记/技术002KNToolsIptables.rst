技术002KNToolsIptables

技术002KNToolsIptables
======================

[] 1. Linux防火墙(Iptables)重启系统生效 开启： chkconfig iptables on
关闭： chkconfig iptables off 2.Linux防火墙(Iptables)
即时生效，重启后失效 开启： service iptables start 关闭： service
iptables stop 规则列表 iptables –line-numbers -nvL Chain INPUT (policy
ACCEPT 0 packets, 0 bytes) num pkts bytes target prot opt in out source
destination 1 126G 214T ACCEPT all – \* \* 0.0.0.0/0 0.0.0.0/0 state
RELATED,ESTABLISHED 2 39M 2738M ACCEPT icmp – \* \* 0.0.0.0/0 0.0.0.0/0
3 3347K 177M ACCEPT all – lo \* 0.0.0.0/0 0.0.0.0/0 4 660M 37G ACCEPT
all – eth0 \* 10.0.0.0/8 0.0.0.0/0

5 232M 15G REJECT all – \* \* 0.0.0.0/0 0.0.0.0/0 reject-with
icmp-host-prohibited

6 0 0 DROP all – \* \* 0.0.0.0/0 0.0.0.0/0 Chain FORWARD (policy ACCEPT
0 packets, 0 bytes) num pkts bytes target prot opt in out source
destination 1 0 0 DOCKER-ISOLATION all – \* \* 0.0.0.0/0 0.0.0.0/0 2 0 0
DOCKER all – \* docker0 0.0.0.0/0 0.0.0.0/0 3 0 0 ACCEPT all – \*
docker0 0.0.0.0/0 0.0.0.0/0 ctstate RELATED,ESTABLISHED 4 0 0 ACCEPT all
– docker0 !docker0 0.0.0.0/0 0.0.0.0/0 5 0 0 ACCEPT all – docker0
docker0 0.0.0.0/0 0.0.0.0/0 6 0 0 REJECT all – \* \* 0.0.0.0/0 0.0.0.0/0
reject-with icmp-host-prohibited Chain OUTPUT (policy ACCEPT 50G
packets, 57T bytes) num pkts bytes target prot opt in out source
destination Chain DOCKER (1 references) num pkts bytes target prot opt
in out source destination Chain DOCKER-ISOLATION (1 references) num pkts
bytes target prot opt in out source destination 1 0 0 RETURN all – \* \*
0.0.0.0/0 0.0.0.0/0 规则添加

iptables -A
添加的规则是添加在最后面。如针对INPUT链增加一条规则，接收从eth0口进入且源地址为192.168.0.0/16网段发往本机的数据。

iptables -A INPUT -i eth0 -s 172.19.0.0/16 -j ACCEPT iptables -I
添加的规则默认添加至第一条。 iptables -I INPUT -i eth0 -s 172.19.0.0/16
-j ACCEPT # 在表ACCEPT中插入第一条数据 iptables -I INPUT -i eth0 -s
172.20.22.0/24 -j ACCEPT # 在表ACCEPT中插入第一条数据 iptables -I INPUT
-i eth0 -s 172.20.24.0/24 -j ACCEPT # 在表ACCEPT中插入第一条数据
删除规则 iptables -t filter -D INPUT 7 # 删除INPUT表中的第7条数据
iptables -t filter -D OUTPUT 1 # 删除OUTPUT表中的第1条数据 service
iptables save 规则数据保存在文件中 /etc/sysconfig/iptables service
iptables save # 将文件保存在/etc/sysconfig/iptables 恢复iptables rules
iptables-restore </dd/iptables.bak
