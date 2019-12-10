技术002KNToolsTCPDUMP

技术002KNToolsTCPDUMP
=====================

tcpdump
http://bencane.com/2014/10/13/quick-and-practical-reference-for-tcpdump/
A Quick and Practical Reference for tcpdump tcpdump -n 不带hostname
tcpdump -vvv -vvv显示更多的ip packets信息 tcpdump -vvvv -c 1
-c显示的行数 tcpdump -i eth0 -i 指定监控的网卡信息，默认是取eth0，
tcpdump -i any any是监控服务器上的所有的网卡 tcpdump -w /path/to/file
-w保存到文件中 tcpdump -r /path/to/file -r从文件中读取 tcpdump -s 100
-s指定packet的长度，默认是65535 bytes filter tcpdump -nvvv -i any -c 3
host 10.0.3.1 过滤host=10.0.3.1的流量 tcpdump -nvvv -i any -c 3 src host
10.0.3.1 只显示source host的流量

tcpdump -nvvv -i any -c 3 port 22 and port 60738
比较有用，只抓取port22和60738之间的流量，或者tcpdump -nvvv -i any -c 3
‘port 22 && port 60738’

tcpdump -nvvv -i any -c 20 ‘port 80 or port 443’ 或 tcpdump -nvvv -i any
-c 20 ‘port 80 or port 443’

tcpdump -nvvv -i any -c 20 ‘(port 80 or port 443) and host 10.0.3.169’

tcpdump -nvvv -i any -c 20 ‘((port 80 or port 443) and (host 10.0.3.169
or host 10.0.3.1)) and dst host 10.0.3.246’ 通过括号来实现运算的优先级别

抓取其他协议ICMP, UDP, and ARP 的包 观察 1.srcip和port dstip和port

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x0388), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989005 ecr 0,nop,wscale 7], length 0

Given the above output we can see that the source ip is 10.0.3.246 the
source port is 56894 and the destination ip is 192.168.0.92 with a
destination port of 22. This is pretty easy to identify once you
understand the format of tcpdump. If you haven’t guessed the format yet
you can break it down as follows src-ip.src-port > dest-ip.dest-port:
Flags[S] the source is in front of the > and the destination is behind.
You can think of the > as an arrow pointing to the destination.

2.packet的类型 以及packet观察

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x0388), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989005 ecr 0,nop,wscale 7], length 0

From the sample above we can tell that the packet is a single SYN
packet. We can identify this by the Flags [S] section of the tcpdump
output, different types of packets have different types of flags.
Without going too deep into what types of packets exist within TCP you
can use the below as a cheat sheet for identifying packet types.

[S] - SYN (Start Connection) [.] - No Flag Set [P] - PSH (Push Data) [F]
- FIN (Finish Connection) [R] - RST (Reset Connection)

Depending on the version and output of tcpdump you may also see flags
such as [S.] this is used to indicate a SYN-ACK packet.

An unhealthy example

15:15:43.323412 IP (tos 0x0, ttl 64, id 51051, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x0388), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989005 ecr 0,nop,wscale 7], length 0

15:15:44.321444 IP (tos 0x0, ttl 64, id 51052, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x028e), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989255 ecr 0,nop,wscale 7], length 0

15:15:46.321610 IP (tos 0x0, ttl 64, id 51053, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x009a), seq 682725

The above sampling shows an example of an unhealthy exchange, and by
unhealthy exchange for this example that means no exchange. In the above
sample we can see that 10.0.3.246 is sending a SYN packet to host
192.168.0.92 however we never see a response from host 192.168.0.92.

A healthy example

15:18:25.716453 IP (tos 0x10, ttl 64, id 53344, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.34908 > 192.168.0.110.22: Flags [S], cksum 0xcf3a (incorrect
-> 0xc838), seq 1943877315, win 29200, options [mss 1460,sackOK,TS val
620029603 ecr 0,nop,wscale 7], length 0

15:18:25.716777 IP (tos 0x0, ttl 63, id 0, offset 0, flags [DF], proto
TCP (6), length 60)

192.168.0.110.22 > 10.0.3.246.34908: Flags [S.], cksum 0x594a (correct),
seq 4001145915, ack 1943877316, win 5792, options [mss 1460,sackOK,TS
val 18495104 ecr 620029603,nop,wscale 2], length 0

15:18:25.716899 IP (tos 0x10, ttl 64, id 53345, offset 0, flags [DF],
proto TCP (6), length 52)

10.0.3.246.34908 > 192.168.0.110.22: Flags [.], cksum 0xcf32 (incorrect
-> 0x9dcc), ack 1, win 229, options [nop,nop,TS val 620029603 ecr
18495104], length 0

A healthy example would look like the above, in the above we can see a
standard TCP 3-way handshake. The first packet above is a SYN packet
from host 10.0.3.246 to host 192.168.0.110, the second packet is a
SYN-ACK from host 192.168.0.110 acknowledging the SYN. The final packet
is a ACK or rather a SYN-ACK-ACK from host 10.0.3.246 acknowledging that
it has received the SYN-ACK. From this point on there is an established
TCP/IP connection.

3.用Hex和ASCII 查看数据包

tcpdump -nvvv -i any -c 1 -XX ‘port 80 and host 10.0.3.1’ -XX flag to
print the packet data in hex and ascii

tcpdump -nvvv -i any -c 1 -A ‘port 80 and host 10.0.3.1’ -A Printing
packet data in ASCII only

通过这种人可读取的格式方便排查问题，如果对于加密的数据，
可以通过ssldump和wireshark。However, if you use have the certificates in
use you could use commands such as ssldump or even wireshark.

tcpdump
http://bencane.com/2014/10/13/quick-and-practical-reference-for-tcpdump/
A Quick and Practical Reference for tcpdump tcpdump -n 不带hostname
tcpdump -vvv -vvv显示更多的ip packets信息 tcpdump -vvvv -c 1
-c显示的行数 tcpdump -i eth0 -i 指定监控的网卡信息，默认是取eth0，
tcpdump -i any any是监控服务器上的所有的网卡 tcpdump -w /path/to/file
-w保存到文件中 tcpdump -r /path/to/file -r从文件中读取 tcpdump -s 100
-s指定packet的长度，默认是65535 bytes filter tcpdump -nvvv -i any -c 3
host 10.0.3.1 过滤host=10.0.3.1的流量 tcpdump -nvvv -i any -c 3 src host
10.0.3.1 只显示source host的流量

tcpdump -nvvv -i any -c 3 port 22 and port 60738
比较有用，只抓取port22和60738之间的流量，或者tcpdump -nvvv -i any -c 3
‘port 22 && port 60738’

tcpdump -nvvv -i any -c 20 ‘port 80 or port 443’ 或 tcpdump -nvvv -i any
-c 20 ‘port 80 or port 443’

tcpdump -nvvv -i any -c 20 ‘(port 80 or port 443) and host 10.0.3.169’

tcpdump -nvvv -i any -c 20 ‘((port 80 or port 443) and (host 10.0.3.169
or host 10.0.3.1)) and dst host 10.0.3.246’ 通过括号来实现运算的优先级别

抓取其他协议ICMP, UDP, and ARP 的包 观察 1.srcip和port dstip和port

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x0388), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989005 ecr 0,nop,wscale 7], length 0

Given the above output we can see that the source ip is 10.0.3.246 the
source port is 56894 and the destination ip is 192.168.0.92 with a
destination port of 22. This is pretty easy to identify once you
understand the format of tcpdump. If you haven’t guessed the format yet
you can break it down as follows src-ip.src-port > dest-ip.dest-port:
Flags[S] the source is in front of the > and the destination is behind.
You can think of the > as an arrow pointing to the destination.

2.packet的类型 以及packet观察

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x0388), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989005 ecr 0,nop,wscale 7], length 0

From the sample above we can tell that the packet is a single SYN
packet. We can identify this by the Flags [S] section of the tcpdump
output, different types of packets have different types of flags.
Without going too deep into what types of packets exist within TCP you
can use the below as a cheat sheet for identifying packet types.

[S] - SYN (Start Connection) [.] - No Flag Set [P] - PSH (Push Data) [F]
- FIN (Finish Connection) [R] - RST (Reset Connection)

Depending on the version and output of tcpdump you may also see flags
such as [S.] this is used to indicate a SYN-ACK packet.

An unhealthy example

15:15:43.323412 IP (tos 0x0, ttl 64, id 51051, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x0388), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989005 ecr 0,nop,wscale 7], length 0

15:15:44.321444 IP (tos 0x0, ttl 64, id 51052, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x028e), seq 682725222, win 29200, options [mss 1460,sackOK,TS val
619989255 ecr 0,nop,wscale 7], length 0

15:15:46.321610 IP (tos 0x0, ttl 64, id 51053, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.56894 > 192.168.0.92.22: Flags [S], cksum 0xcf28 (incorrect
-> 0x009a), seq 682725

The above sampling shows an example of an unhealthy exchange, and by
unhealthy exchange for this example that means no exchange. In the above
sample we can see that 10.0.3.246 is sending a SYN packet to host
192.168.0.92 however we never see a response from host 192.168.0.92.

A healthy example

15:18:25.716453 IP (tos 0x10, ttl 64, id 53344, offset 0, flags [DF],
proto TCP (6), length 60)

10.0.3.246.34908 > 192.168.0.110.22: Flags [S], cksum 0xcf3a (incorrect
-> 0xc838), seq 1943877315, win 29200, options [mss 1460,sackOK,TS val
620029603 ecr 0,nop,wscale 7], length 0

15:18:25.716777 IP (tos 0x0, ttl 63, id 0, offset 0, flags [DF], proto
TCP (6), length 60)

192.168.0.110.22 > 10.0.3.246.34908: Flags [S.], cksum 0x594a (correct),
seq 4001145915, ack 1943877316, win 5792, options [mss 1460,sackOK,TS
val 18495104 ecr 620029603,nop,wscale 2], length 0

15:18:25.716899 IP (tos 0x10, ttl 64, id 53345, offset 0, flags [DF],
proto TCP (6), length 52)

10.0.3.246.34908 > 192.168.0.110.22: Flags [.], cksum 0xcf32 (incorrect
-> 0x9dcc), ack 1, win 229, options [nop,nop,TS val 620029603 ecr
18495104], length 0

A healthy example would look like the above, in the above we can see a
standard TCP 3-way handshake. The first packet above is a SYN packet
from host 10.0.3.246 to host 192.168.0.110, the second packet is a
SYN-ACK from host 192.168.0.110 acknowledging the SYN. The final packet
is a ACK or rather a SYN-ACK-ACK from host 10.0.3.246 acknowledging that
it has received the SYN-ACK. From this point on there is an established
TCP/IP connection.

3.用Hex和ASCII 查看数据包

tcpdump -nvvv -i any -c 1 -XX ‘port 80 and host 10.0.3.1’ -XX flag to
print the packet data in hex and ascii

tcpdump -nvvv -i any -c 1 -A ‘port 80 and host 10.0.3.1’ -A Printing
packet data in ASCII only

通过这种人可读取的格式方便排查问题，如果对于加密的数据，
可以通过ssldump和wireshark。However, if you use have the certificates in
use you could use commands such as ssldump or even wireshark.
