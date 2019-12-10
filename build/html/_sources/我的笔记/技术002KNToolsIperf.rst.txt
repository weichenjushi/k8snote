技术002KNToolsIperf

技术002KNToolsIperf
===================

iperf 命令是一个网络性能测试工具。iperf 可以测试 TCP 和 UDP
带宽质量。iperf 可以测量最大 TCP 带宽，具有多种参数和 UDP 特性。iperf
可以报告带宽，延迟抖动和数据包丢失。利用 iperf
这一特性，可以用来测试一些网络设备如路由器，防火墙，交换机等的性能。

iperf 使用简单的 C/S 架构，客户端使用 -c， 服务端使用 -s。
iperf和iperf3常用命令如下 服务端常用命令： iperf/iperf3 -s
启动服务端，默认协议tcp，默认端口5001 iperf -s -w 32M -D / iperf3 -s -D
以守护进程启动服务端，tcp窗口大小为32M iperf -i1 -u -s -p 5003 / iperf3
-s -p 5003 启动udp协议服务端，监听端口5003 客户端常用命令： iperf/iperf3
-c serverIP -i 1 -t 30 压测30s，每1s输出一次 iperff/iperf3 -c serverIP
-i 1 -t 20 -r 逆向执行，从服务端到本地 iperf/iperf3 -c serverIP -i 1 -t
20 -w 32M -P 4 4个并发，窗口大小进程压测 iperf/iperf3 -c serverIP -u -i
1 -b 200M 测试 200M UDP协议 iperf3还支持其他特性。 iperf3 -c
10.103.17.184 -i.5 -O 2 忽略掉前2s的数据包，该命令用于支持TCP的慢启动
iperf3 -Z -c 10.103.17.184 通过系统调用sendfile()
实现“零拷贝”效果。消耗较少CPU。 iperf3 -c 10.103.17.184 -T s1 & iperf3
-c 10.103.17.184 -T s2 通知执行测试s1，s2并进行比较。 iperf3 -c
10.103.17.184 -J 以json的格式输出数据 iperf3 -A 4,4 -c 10.103.17.184
设置发送者和接受者的CPU的核数（从0开始）

iperf3 -c 10.103.17.184 -A2,2 -T “1” & ; iperf3 -c 10.103.17.184 -p 5202
-A3,3 -T “2” & 在CPU核“1”和核“2”进行两个测试
