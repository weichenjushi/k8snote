技术002KELK

技术002KELK
===========

-  `技术002KELK <>`__

   -  `Filebeat <>`__

      -  `Debug <>`__
      -  `参考文档 <>`__
      -  `示例配置文件 <>`__

   -  `Logstash <>`__

      -  `Output <>`__

         -  `Kafka <>`__

      -  `参考文档 <>`__
      -  `实例配置文件 <>`__

   -  `Elasticearch <>`__
   -  `Fluentd <>`__
   -  `问题记录 <>`__

      -  `问题排查过程记录1 <>`__

Filebeat
--------

(1)Offset is the number of bytes read. filebeat
对于会把每个文件的offset保存在路径/usr/share/filebeat/data/registry下

(2)filebeat->不能fluentd

Debug
~~~~~

1.log.level 设置为 debug 2.filebeat -c /etc/filebeat/filebeat1.yml -e -d
“*" 3.filebeat test output -c /etc/filebeat/filebeat1.yml

参考文档
~~~~~~~~

https://www.elastic.co/guide/en/beats/filebeat/6.3/faq.html#filebeat-not-collecting-lines

示例配置文件
~~~~~~~~~~~~

::

   filebeat.inputs:

   - type: log

     enabled: true
     paths:

     - /log/*
     - /log/*/*
     - /log/*/*/*

     fields:
       service: '${K8S_SERVICE}'
       env: '${K8S_ENV}'
       k8sNS: '${K8S_NAMESPACE}'
       k8sCluster: '${K8S_CLUSTER}’
     #处理单条消息最大值为1m
     max_bytes: 1048576
     fields_under_root: true
     exclude_files: ['\.gz$']
   # 从registry文件中关闭已经更改名字的文件
   close_renamed: true
   # 从registry文件中关闭已经关闭的文件
   close_removed: true
   # 从registry文件中移除已经关闭的文件
   clean_removed: true
   # 不活跃48h就关闭
   close_inactive: 48h
   ignore_older: 48h
   clean_inactive: 72h
   scan_frequency: 3s
   multiline.max_lines: 10
   setup.template.enabled: false
   output.logstash:
     hosts: 'app-logs-k8s-sh.transfer.int.yidian-inc.com:5044'
     timeout: 60
   #默认级别是info
   logging.level: debug

Logstash
--------

logstash jvm调整 1.Xms和Xmx调整一样，最好为物理内存的一半
https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html
logstash插件地址： https://github.com/logstash-plugins logstash
不能remove \_id \_index \_score
\_type等字段，因为这些字段是作为es的元数据

Output
~~~~~~

Kafka
^^^^^

https://www.elastic.co/guide/en/logstash/6.4/plugins-outputs-kafka.html#plugins-outputs-kafka-batch_size

.. _参考文档-1:

参考文档
~~~~~~~~

`不采用logstash的原因 <https://my.oschina.net/u/2612999/blog/1518876?p=2>`__

实例配置文件
~~~~~~~~~~~~

::

   logstash.conf: |-
       input {
         beats {
           port => 5044
         }
       }
       filter {
          mutate {
              remove_field => [ "@timestamp","@metadata", "@version", "offset", "prospector", "input", "beat", "tags"]
          }
       }
       output {
         kafka {
            bootstrap_servers => "10.120.11.25:9099,10.103.35.25:9099,10.103.187.35:9099,10.103.187.36:9099,10.103.33.176:9099,10.103.33.178:9099,10.103.33.180:9099,10.120.11.26:9099,10.120.11.27:9099"
            codec => json
            topic_id =>  "applog-sh-%{service}-%{env}"
            max_request_size => 8000000
            batch_size => 10000
            message_key => "%{[host][name]}"
            acks => "1"
         }
       }

Elasticearch
------------

es max number of index
https://discuss.elastic.co/t/max-number-of-indices/97932 1. curl
删除es索引出现的问题 curl -sSL -XDELETE
‘http://el:9200/osquery-mounts-%%{host}’ Use %% to escape %, use
backslash to escape { and } es中的索引必须小写 2.
将number的timestamp转换成Date类型用作TimeFileter的index logstash中配置
date { match => [ “source_timestamp” , “yyyy-MM-dd HH:mm:ss.SSS” ]
target => “source_timestamp” } 或者在es中配置
http://10.126.167.4:40000/_template/ “properties”: { “source_timestamp”:
{ “type”: “date”, “format”: “yyyy-MM-dd
HH:mm:ss||yyyy-MM-dd||epoch_millis” }, }

Fluentd
-------

https://docs.fluentd.org/output/elasticsearch

问题记录
--------

问题排查过程记录1
~~~~~~~~~~~~~~~~~

1. 过程1 目前logstash存在的问题有 现象有：
   (1)通过lvs代理的多个logstash只有一个节点在处理数据
   (2)相同服务，有的pod日志可以搜集到，有的搜不到，也就是有的filebeat无法发送数据到logstash
   问题有：

(1)logstash启动后，一会儿报错“message”:"org.apache.kafka.common.errors.RecordTooLargeException:
The message is 1679038 bytes when serialized which is larger than the
maximum request size you have configured with the max.request.size
configuration.

{“level”:“WARN”,“loggerName”:“logstash.outputs.kafka”,“timeMillis”:1555085898245,“thread”:“Ruby-0-Thread-6@[main]>worker0:
:1”,“logEvent”:{“message”:“KafkaProducer.send() failed:
org.apache.kafka.common.errors.RecordTooLargeException: The message is
1679038 bytes when serialized which is larger than the maximum request
size you have configured with the max.request.size
configuration.”,“exception”:{“cause”:{“message”:“The message is 1679038
bytes when serialized which is larger than the maximum request size you
have configured with the max.request.size
configuration.”,“localizedMessage”:“The message is 1679038 bytes when
serialized which is larger than the maximum request size you have
configured with the max.request.size
configuration.”},“stackTrace”:[{“class”:“org.apache.kafka.clients.producer.KafkaProducer$FutureFailure”,“method”:“”,“file”:“org/apache/kafka/clients/producer/KafkaProducer.java”,“line”:1150},{“class”:“org.apache.kafka.clients.producer.KafkaProducer”,“method”:“doSend”,“file”:“org/apache/kafka/clients/producer/KafkaProducer.java”,“line”:846},{“class”:“org.apache.kafka.clients.producer.KafkaProducer”,“method”:“send”,“file”:“org/apache/kafka/clients/producer/KafkaProducer.java”,“line”:784},{“class”:“org.apache.kafka.clients.producer.KafkaProducer”,“method”:“send”,“file”:“org/apache/kafka/clients/producer/KafkaProducer.java”,“line”:671},{“class”:“java.lang.reflect.Method”,“method”:“invoke”,“file”:“java/lang/reflect/Method.java”,“line”:498},{“class”:“org.jruby.javasupport.JavaMethod”,“method”:“invokeDirectWithExceptionHandling”,“file”:“org/jruby/javasupport/JavaMethod.java”,“line”:453},{“class”:“org.jruby.javasupport.JavaMethod”,“method”:“invokeDirect”,“file”:“org/jruby/javasupport/JavaMethod.java”,“line”:314},{“class”:“usr.share.logstash.vendor.bundle.jruby.$2_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka”,“method”:“block
in
retrying_send”,“file”:“/usr/share/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-output-kafka-7.1.1/lib/logstash/outputs/kafka.rb”,“line”:253},{“class”:“org.jruby.RubyArray”,“method”:“collect”,“file”:“org/jruby/RubyArray.java”,“line”:2472},{“class”:“org.jruby.RubyArray”,“method”:“collect”,“file”:“org/jruby/RubyArray.java”,“line”:2481},{“class”:“usr.share.logstash.vendor.bundle.jruby.$2_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka”,“method”:“retrying_send”,“file”:“/usr/share/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-output-kafka-7.1.1/lib/logstash/outputs/kafka.rb”,“line”:250},{“class”:“usr.share.logstash.vendor.bundle.jruby.2_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka”,“method”:“multi_receive”,“file”:“/usr/share/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-output-kafka-7.1.1/lib/logstash/outputs/kafka.rb”,“line”:226},{“class”:“org.jruby.RubyClass”,“method”:“finvoke”,“file”:“org/jruby/RubyClass.java”,“line”:908},{“class”:“org.jruby.RubyBasicObject”,“method”:“callMethod”,“file”:“org/jruby/RubyBasicObject.java”,“line”:363},{“class”:“org.logstash.config.ir.compiler.OutputStrategyExtSimpleAbstractOutputStrategyExt”,“method”:“doOutput”,“file”:“org/logstash/config/ir/compiler/OutputStrategyExt.java”,“line”:219},{“class”:“org.logstash.config.ir.compiler.OutputStrategyExtSharedOutputStrategyExt”,“method”:“output”,“file”:“org/logstash/config/ir/compiler/OutputStrategyExt.java”,“line”:247},{“class”:“org.logstash.config.ir.compiler.OutputStrategyExtAbstractOutputStrategyExt”,“method”:“multi_receive”,“file”:“org/logstash/config/ir/compiler/OutputStrategyExt.java”,“line”:109},{“class”:“org.logstash.config.ir.compiler.OutputDelegatorExt”,“method”:“multi_receive”,“file”:“org/logstash/config/ir/compiler/OutputDelegatorExt.java”,“line”:156},{“class”:“usr.share.logstash.logstash_minus_core.lib.logstash.pipeline”,“method”:“block
in
output_batch”,“file”:“/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb”,“line”:475},{“class”:“org.jruby.RubyHash\ :math:`12","method":"visit","file":"org/jruby/RubyHash.java","line":1362},{"class":"org.jruby.RubyHash12","method":"visit","file":"org/jruby/RubyHash.java","line":1359},{"class":"org.jruby.RubyHash","method":"visitLimited","file":"org/jruby/RubyHash.java","line":662},{"class":"org.jruby.RubyHash","method":"visitAll","file":"org/jruby/RubyHash.java","line":647},{"class":"org.jruby.RubyHash","method":"iteratorVisitAll","file":"org/jruby/RubyHash.java","line":1319},{"class":"org.jruby.RubyHash","method":"each_pairCommon","file":"org/jruby/RubyHash.java","line":1354},{"class":"org.jruby.RubyHash","method":"each","file":"org/jruby/RubyHash.java","line":1343},{"class":"usr.share.logstash.logstash_minus_core.lib.logstash.pipeline","method":"output_batch","file":"/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb","line":474},{"class":"usr.share.logstash.logstash_minus_core.lib.logstash.pipeline","method":"worker_loop","file":"/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb","line":426},{"class":"usr.share.logstash.logstash_minus_core.lib.logstash.pipeline","method":"RUBYmethod`\ worker_loop0\ **VARARGS**”,“file”:“usr/share/logstash/logstash_minus_core/lib/logstash//usr/share/logstash/logstash-core/lib/logstash/pipeline.rb”,“line”:-1},{“class”:“usr.share.logstash.logstash_minus_core.lib.logstash.pipeline”,“method”:“block
in
start_workers”,“file”:“/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb”,“line”:384},{“class”:“org.jruby.RubyProc”,“method”:“call”,“file”:“org/jruby/RubyProc.java”,“line”:289},{“class”:“org.jruby.RubyProc”,“method”:“call”,“file”:“org/jruby/RubyProc.java”,“line”:246},{“class”:“java.lang.Thread”,“method”:“run”,“file”:“java/lang/Thread.java”,“line”:748}],“message”:“org.apache.kafka.common.errors.RecordTooLargeException:
The message is 1679038 bytes when serialized which is larger than the
maximum request size you have configured with the max.request.size
configuration.”,“localizedMessage”:“org.apache.kafka.common.errors.RecordTooLargeException:
The message is 1679038 bytes when serialized which is larger than the
maximum request size you have configured with the max.request.size
configuration.”}}}

(2)logstash启动后，一会儿报错“localizedMessage”:“org.apache.kafka.common.errors.RecordTooLargeException:
The request included a message larger than the max message size the
server will accept.”}}}

{“level”:“WARN”,“loggerName”:“logstash.outputs.kafka”,“timeMillis”:1555087294303,“thread”:“Ruby-0-Thread-6@[main]>worker0:
:1”,“logEvent”:{“message”:“KafkaProducer.send() failed:
org.apache.kafka.common.errors.RecordTooLargeException: The request
included a message larger than the max message size the server will
accept.”,“exception”:{“cause”:{“message”:“The request included a message
larger than the max message size the server will
accept.”,“localizedMessage”:“The request included a message larger than
the max message size the server will
accept.”},“stackTrace”:[{“class”:“org.apache.kafka.clients.producer.internals.FutureRecordMetadata”,“method”:“valueOrError”,“file”:“org/apache/kafka/clients/producer/internals/FutureRecordMetadata.java”,“line”:94},{“class”:“org.apache.kafka.clients.producer.internals.FutureRecordMetadata”,“method”:“get”,“file”:“org/apache/kafka/clients/producer/internals/FutureRecordMetadata.java”,“line”:64},{“class”:“org.apache.kafka.clients.producer.internals.FutureRecordMetadata”,“method”:“get”,“file”:“org/apache/kafka/clients/producer/internals/FutureRecordMetadata.java”,“line”:29},{“class”:“java.lang.reflect.Method”,“method”:“invoke”,“file”:“java/lang/reflect/Method.java”,“line”:498},{“class”:“org.jruby.javasupport.JavaMethod”,“method”:“invokeDirectWithExceptionHandling”,“file”:“org/jruby/javasupport/JavaMethod.java”,“line”:438},{“class”:“org.jruby.javasupport.JavaMethod”,“method”:“invokeDirect”,“file”:“org/jruby/javasupport/JavaMethod.java”,“line”:302},{“class”:“usr.share.logstash.vendor.bundle.jruby.2_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka”,“method”:“block
in
retrying_send”,“file”:“/usr/share/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-output-kafka-7.1.1/lib/logstash/outputs/kafka.rb”,“line”:270},{“class”:“org.jruby.RubyEnumerableEachWithIndex”,“method”:“call”,“file”:“org/jruby/RubyEnumerable.java”,“line”:1003},{“class”:“org.jruby.RubyArray”,“method”:“each”,“file”:“org/jruby/RubyArray.java”,“line”:1734},{“class”:“org.jruby.RubyArray\ *I\ *\ **N**\ *\ V\ *\ **O**\ *\ K\ *\ **E**\ *\ R*\ i$00each”,“method”:“call”,“file”:“org/jruby/RubyArray\ *I\ *\ **N**\ *\ V\ *\ **O**\ *\ K\ *\ **E**\ *\ R*\ i$00each.gen”,“line”:-1},{“class”:“org.jruby.RubyClass”,“method”:“finvoke”,“file”:“org/jruby/RubyClass.java”,“line”:522},{“class”:“org.jruby.RubyEnumerable”,“method”:“callEach”,“file”:“org/jruby/RubyEnumerable.java”,“line”:140},{“class”:“org.jruby.RubyEnumerable”,“method”:“each_with_indexCommon”,“file”:“org/jruby/RubyEnumerable.java”,“line”:1037},{“class”:“org.jruby.RubyEnumerable”,“method”:“each_with_index”,“file”:“org/jruby/RubyEnumerable.java”,“line”:1067},{“class”:“usr.share.logstash.vendor.bundle.jruby.$2_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka”,“method”:“retrying_send”,“file”:“/usr/share/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-output-kafka-7.1.1/lib/logstash/outputs/kafka.rb”,“line”:268},{“class”:“usr.share.logstash.vendor.bundle.jruby.2_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka”,“method”:“multi_receive”,“file”:“/usr/share/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-output-kafka-7.1.1/lib/logstash/outputs/kafka.rb”,“line”:226},{“class”:“org.jruby.RubyClass”,“method”:“finvoke”,“file”:“org/jruby/RubyClass.java”,“line”:908},{“class”:“org.jruby.RubyBasicObject”,“method”:“callMethod”,“file”:“org/jruby/RubyBasicObject.java”,“line”:363},{“class”:“org.logstash.config.ir.compiler.OutputStrategyExtSimpleAbstractOutputStrategyExt”,“method”:“doOutput”,“file”:“org/logstash/config/ir/compiler/OutputStrategyExt.java”,“line”:219},{“class”:“org.logstash.config.ir.compiler.OutputStrategyExtSharedOutputStrategyExt”,“method”:“output”,“file”:“org/logstash/config/ir/compiler/OutputStrategyExt.java”,“line”:247},{“class”:“org.logstash.config.ir.compiler.OutputStrategyExtAbstractOutputStrategyExt”,“method”:“multi_receive”,“file”:“org/logstash/config/ir/compiler/OutputStrategyExt.java”,“line”:109},{“class”:“org.logstash.config.ir.compiler.OutputDelegatorExt”,“method”:“multi_receive”,“file”:“org/logstash/config/ir/compiler/OutputDelegatorExt.java”,“line”:156},{“class”:“usr.share.logstash.logstash_minus_core.lib.logstash.pipeline”,“method”:“block
in
output_batch”,“file”:“/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb”,“line”:475},{“class”:“org.jruby.RubyHash\ :math:`12","method":"visit","file":"org/jruby/RubyHash.java","line":1362},{"class":"org.jruby.RubyHash12","method":"visit","file":"org/jruby/RubyHash.java","line":1359},{"class":"org.jruby.RubyHash","method":"visitLimited","file":"org/jruby/RubyHash.java","line":662},{"class":"org.jruby.RubyHash","method":"visitAll","file":"org/jruby/RubyHash.java","line":647},{"class":"org.jruby.RubyHash","method":"iteratorVisitAll","file":"org/jruby/RubyHash.java","line":1319},{"class":"org.jruby.RubyHash","method":"each_pairCommon","file":"org/jruby/RubyHash.java","line":1354},{"class":"org.jruby.RubyHash","method":"each","file":"org/jruby/RubyHash.java","line":1343},{"class":"usr.share.logstash.logstash_minus_core.lib.logstash.pipeline","method":"output_batch","file":"/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb","line":474},{"class":"usr.share.logstash.logstash_minus_core.lib.logstash.pipeline","method":"worker_loop","file":"/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb","line":426},{"class":"usr.share.logstash.logstash_minus_core.lib.logstash.pipeline","method":"RUBYmethod`\ worker_loop0\ **VARARGS**”,“file”:“usr/share/logstash/logstash_minus_core/lib/logstash//usr/share/logstash/logstash-core/lib/logstash/pipeline.rb”,“line”:-1},{“class”:“usr.share.logstash.logstash_minus_core.lib.logstash.pipeline”,“method”:“block
in
start_workers”,“file”:“/usr/share/logstash/logstash-core/lib/logstash/pipeline.rb”,“line”:384},{“class”:“org.jruby.RubyProc”,“method”:“call”,“file”:“org/jruby/RubyProc.java”,“line”:289},{“class”:“org.jruby.RubyProc”,“method”:“call”,“file”:“org/jruby/RubyProc.java”,“line”:246},{“class”:“java.lang.Thread”,“method”:“run”,“file”:“java/lang/Thread.java”,“line”:748}],“message”:“org.apache.kafka.common.errors.RecordTooLargeException:
The request included a message larger than the max message size the
server will
accept.”,“localizedMessage”:“org.apache.kafka.common.errors.RecordTooLargeException:
The request included a message larger than the max message size the
server will accept.”}}}

解决思路： (1)排除lvs的影响，由filebeat直接连接logstash的ip地址，
更改配置由hosts: ‘app-logs-k8s-sh.transfer.int.yidian-inc.com:5044’
更改为 hosts: [“172.19.2.238:5044”,
“172.19.2.85:5044”,“172.19.5.23:5044”] 发现没什么作用

并且多次重启filebeat发现有时候就能正常发送日志，有的不能，很郁闷，不断地修改filebeat配置文件，直到第二天早上无意中发现有一个logstash实例能正常work，但是其他的实例都在报错，如以上两个问题

(2)针对于问题1，logstash to
kafka的插件配置参数max_request_size默认是1048576，而kafka集群中的能处理的消息最大值为8M，max.message.size=8388608，于是调整参数max_request_size
=> 8000000

(3)重启logstash后一会儿又挂了，并报错(2),kafka的参数不能再往大的调整，但是一直卡在了这里，于是retries=>10
,尝试10次，如果失败的话，那么就跳过event,然后再将该参数删除。同时观察到filebeat中消息的最大值是10m,明显kafka集群不能处理，所以修改参数filebeat参数为1m,
max_bytes: 1048576,
根据报错信息(1)调整logstash一批发送数据的大小参数batch_size默认是16384,batch_size
=> 10000,然后重启logstash发现没问题了。

最终filebeat的配置文件为：

::

   filebeat.inputs:

   - type: log

     enabled: true
     paths:

     - /log/*
     - /log/*/*
     - /log/*/*/*

     fields:
       service: '${K8S_SERVICE}'
       env: '${K8S_ENV}'
       k8sNS: '${K8S_NAMESPACE}'
       k8sCluster: '${K8S_CLUSTER}’
     #处理单条消息最大值为1m
     max_bytes: 1048576
     fields_under_root: true
     exclude_files: ['\.gz$']
   # 从registry文件中关闭已经更改名字的文件
   close_renamed: true
   # 从registry文件中关闭已经关闭的文件
   close_removed: true
   # 从registry文件中移除已经关闭的文件
   clean_removed: true
   # 不活跃48h就关闭
   close_inactive: 48h
   ignore_older: 48h
   clean_inactive: 72h
   scan_frequency: 3s
   multiline.max_lines: 10
   setup.template.enabled: false
   output.logstash:
     hosts: 'app-logs-k8s-sh.transfer.int.yidian-inc.com:5044'
     timeout: 60
   #默认级别是info
   logging.level: debug
   logstash的配置文件为：
   logstash.conf: |-
       input {
         beats {
           port => 5044
         }
       }
       filter {
          mutate {
              remove_field => [ "@timestamp","@metadata", "@version", "offset", "prospector", "input", "beat", "tags"]
          }
       }
       output {
         kafka {
            bootstrap_servers => "10.120.11.25:9099,10.103.35.25:9099,10.103.187.35:9099,10.103.187.36:9099,10.103.33.176:9099,10.103.33.178:9099,10.103.33.180:9099,10.120.11.26:9099,10.120.11.27:9099"
            codec => json
            topic_id =>  "applog-sh-%{service}-%{env}"
            max_request_size => 8000000
            batch_size => 10000
            message_key => "%{[host][name]}"
            acks => "1"
         }
       }

%23%20%E6%8A%80%E6%9C%AF002KELK%0A%5BTOC%5D%0A%0A%23%23%20Filebeat%0A(1)Offset%20is%20the%20number%20of%20bytes%20read.%20filebeat%20%E5%AF%B9%E4%BA%8E%E4%BC%9A%E6%8A%8A%E6%AF%8F%E4%B8%AA%E6%96%87%E4%BB%B6%E7%9A%84offset%E4%BF%9D%E5%AD%98%E5%9C%A8%E8%B7%AF%E5%BE%84%2Fusr%2Fshare%2Ffilebeat%2Fdata%2Fregistry%E4%B8%8B%0A(2)filebeat-%3E%E4%B8%8D%E8%83%BDfluentd%0A%0A%0A%0A%23%23%23%20Debug%0A1.log.level%20%E8%AE%BE%E7%BD%AE%E4%B8%BA%20debug%0A2.filebeat%20-c%20%2Fetc%2Ffilebeat%2Ffilebeat1.yml%20-e%20-d%20%E2%80%9C\ *%22%0A3.filebeat%20test%20output%20-c%20%2Fetc%2Ffilebeat%2Ffilebeat1.yml%0A%0A%23%23%23%20%E5%8F%82%E8%80%83%E6%96%87%E6%A1%A3%0Ahttps%3A%2F%2Fwww.elastic.co%2Fguide%2Fen%2Fbeats%2Ffilebeat%2F6.3%2Ffaq.html%23filebeat-not-collecting-lines%0A%0A%0A%23%23%23%20%E7%A4%BA%E4%BE%8B%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%0A%60%60%60%0Afilebeat.inputs%3A%0A-%20type%3A%20log%0A%20%20enabled%3A%20true%0A%20%20paths%3A%0A%20%20-%20%2Flog%2F*\ %0A%20%20-%20%2Flog%2F\ *%2F*\ %0A%20%20-%20%2Flog%2F\ *%2F*\ %2F*%0A%20%20fields%3A%0A%20%20%20%20service%3A%20’%24%7BK8S_SERVICE%7D’%0A%20%20%20%20env%3A%20’%24%7BK8S_ENV%7D’%0A%20%20%20%20k8sNS%3A%20’%24%7BK8S_NAMESPACE%7D’%0A%20%20%20%20k8sCluster%3A%20’%24%7BK8S_CLUSTER%7D%E2%80%99%0A%20%20%23%E5%A4%84%E7%90%86%E5%8D%95%E6%9D%A1%E6%B6%88%E6%81%AF%E6%9C%80%E5%A4%A7%E5%80%BC%E4%B8%BA1m%20%0A%20%20max_bytes%3A%201048576%0A%20%20fields_under_root%3A%20true%0A%20%20exclude_files%3A%20%5B’%5C.gz%24’%5D%0A%23%20%E4%BB%8Eregistry%E6%96%87%E4%BB%B6%E4%B8%AD%E5%85%B3%E9%97%AD%E5%B7%B2%E7%BB%8F%E6%9B%B4%E6%94%B9%E5%90%8D%E5%AD%97%E7%9A%84%E6%96%87%E4%BB%B6%0Aclose_renamed%3A%20true%0A%23%20%E4%BB%8Eregistry%E6%96%87%E4%BB%B6%E4%B8%AD%E5%85%B3%E9%97%AD%E5%B7%B2%E7%BB%8F%E5%85%B3%E9%97%AD%E7%9A%84%E6%96%87%E4%BB%B6%0Aclose_removed%3A%20true%0A%23%20%E4%BB%8Eregistry%E6%96%87%E4%BB%B6%E4%B8%AD%E7%A7%BB%E9%99%A4%E5%B7%B2%E7%BB%8F%E5%85%B3%E9%97%AD%E7%9A%84%E6%96%87%E4%BB%B6%0Aclean_removed%3A%20true%0A%23%20%E4%B8%8D%E6%B4%BB%E8%B7%8348h%E5%B0%B1%E5%85%B3%E9%97%AD%0Aclose_inactive%3A%2048h%0Aignore_older%3A%2048h%0Aclean_inactive%3A%2072h%0Ascan_frequency%3A%203s%0Amultiline.max_lines%3A%2010%0Asetup.template.enabled%3A%20false%0Aoutput.logstash%3A%0A%20%20hosts%3A%20’app-logs-k8s-sh.transfer.int.yidian-inc.com%3A5044’%0A%20%20timeout%3A%2060%0A%23%E9%BB%98%E8%AE%A4%E7%BA%A7%E5%88%AB%E6%98%AFinfo%0Alogging.level%3A%20debug%0A%60%60%60%0A%0A%0A%23%23%20Logstash%0Alogstash%20jvm%E8%B0%83%E6%95%B4%0A1.Xms%E5%92%8CXmx%E8%B0%83%E6%95%B4%E4%B8%80%E6%A0%B7%EF%BC%8C%E6%9C%80%E5%A5%BD%E4%B8%BA%E7%89%A9%E7%90%86%E5%86%85%E5%AD%98%E7%9A%84%E4%B8%80%E5%8D%8A%0Ahttps%3A%2F%2Fwww.elastic.co%2Fguide%2Fen%2Felasticsearch%2Freference%2Fcurrent%2Fheap-size.html%0A%0Alogstash%E6%8F%92%E4%BB%B6%E5%9C%B0%E5%9D%80%EF%BC%9A%0Ahttps%3A%2F%2Fgithub.com%2Flogstash-plugins%0A%0Alogstash%20%E4%B8%8D%E8%83%BDremove%20_id%20_index%20_score%20_type%E7%AD%89%E5%AD%97%E6%AE%B5%EF%BC%8C%E5%9B%A0%E4%B8%BA%E8%BF%99%E4%BA%9B%E5%AD%97%E6%AE%B5%E6%98%AF%E4%BD%9C%E4%B8%BAes%E7%9A%84%E5%85%83%E6%95%B0%E6%8D%AE%0A%0A%0A%23%23%23%20Output%0A%23%23%23%23%20Kafka%0Ahttps%3A%2F%2Fwww.elastic.co%2Fguide%2Fen%2Flogstash%2F6.4%2Fplugins-outputs-kafka.html%23plugins-outputs-kafka-batch_size%0A%0A%23%23%23%20%E5%8F%82%E8%80%83%E6%96%87%E6%A1%A3%0A%5B%E4%B8%8D%E9%87%87%E7%94%A8logstash%E7%9A%84%E5%8E%9F%E5%9B%A0%5D(https%3A%2F%2Fmy.oschina.net%2Fu%2F2612999%2Fblog%2F1518876%3Fp%3D2)%0A%0A%23%23%23%20%E5%AE%9E%E4%BE%8B%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%0A%60%60%60%0Alogstash.conf%3A%20%7C-%0A%20%20%20%20input%20%7B%0A%20%20%20%20%20%20beats%20%7B%0A%20%20%20%20%20%20%20%20port%20%3D%3E%205044%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%20%20filter%20%7B%0A%20%20%20%20%20%20%20mutate%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20remove_field%20%3D%3E%20%5B%20%22%40timestamp%22%2C%22%40metadata%22%2C%20%22%40version%22%2C%20%22offset%22%2C%20%22prospector%22%2C%20%22input%22%2C%20%22beat%22%2C%20%22tags%22%5D%0A%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%20%20output%20%7B%0A%20%20%20%20%20%20kafka%20%7B%0A%20%20%20%20%20%20%20%20%20bootstrap_servers%20%3D%3E%20%2210.120.11.25%3A9099%2C10.103.35.25%3A9099%2C10.103.187.35%3A9099%2C10.103.187.36%3A9099%2C10.103.33.176%3A9099%2C10.103.33.178%3A9099%2C10.103.33.180%3A9099%2C10.120.11.26%3A9099%2C10.120.11.27%3A9099%22%0A%20%20%20%20%20%20%20%20%20codec%20%3D%3E%20json%0A%20%20%20%20%20%20%20%20%20topic_id%20%3D%3E%20%20%22applog-sh-%25%7Bservice%7D-%25%7Benv%7D%22%0A%20%20%20%20%20%20%20%20%20max_request_size%20%3D%3E%208000000%0A%20%20%20%20%20%20%20%20%20batch_size%20%3D%3E%2010000%0A%20%20%20%20%20%20%20%20%20message_key%20%3D%3E%20%22%25%7B%5Bhost%5D%5Bname%5D%7D%22%0A%20%20%20%20%20%20%20%20%20acks%20%3D%3E%20%221%22%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%60%60%60%0A%0A%0A%23%23%20Elasticearch%0Aes%20max%20number%20of%20index%0Ahttps%3A%2F%2Fdiscuss.elastic.co%2Ft%2Fmax-number-of-indices%2F97932%0A%0A1.%20curl%20%E5%88%A0%E9%99%A4es%E7%B4%A2%E5%BC%95%E5%87%BA%E7%8E%B0%E7%9A%84%E9%97%AE%E9%A2%98%0Acurl%20-sSL%20-XDELETE%20’http%3A%2F%2Fel%3A9200%2Fosquery-mounts-%25%25%5C%7Bhost%5C%7D’%0AUse%20%25%25%20to%20escape%20%25%2C%20use%20backslash%20to%20escape%20%7B%20and%20%7D%0Aes%E4%B8%AD%E7%9A%84%E7%B4%A2%E5%BC%95%E5%BF%85%E9%A1%BB%E5%B0%8F%E5%86%99%0A%0A2.%20%E5%B0%86number%E7%9A%84timestamp%E8%BD%AC%E6%8D%A2%E6%88%90Date%E7%B1%BB%E5%9E%8B%E7%94%A8%E4%BD%9CTimeFileter%E7%9A%84index%0Alogstash%E4%B8%AD%E9%85%8D%E7%BD%AE%0Adate%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20%20%20match%20%3D%3E%20%5B%20%22source_timestamp%22%20%2C%20%22yyyy-MM-dd%20HH%3Amm%3Ass.SSS%22%20%5D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20target%20%3D%3E%20%22source_timestamp%22%0A%20%20%20%20%20%20%20%20%7D%0A%E6%88%96%E8%80%85%E5%9C%A8es%E4%B8%AD%E9%85%8D%E7%BD%AE%0Ahttp%3A%2F%2F10.126.167.4%3A40000%2F_template%2F%0A%22properties%22%3A%20%7B%0A%22source_timestamp%22%3A%20%7B%0A%22type%22%3A%20%22date%22%2C%0A%22format%22%3A%20%22yyyy-MM-dd%20HH%3Amm%3Ass%7C%7Cyyyy-MM-dd%7C%7Cepoch_millis%22%0A%7D%2C%0A%7D%0A%0A%0A%0A%23%23%20Fluentd%0A%0Ahttps%3A%2F%2Fdocs.fluentd.org%2Foutput%2Felasticsearch%0A%0A%0A%0A%0A%23%23%20%E9%97%AE%E9%A2%98%E8%AE%B0%E5%BD%95%0A%23%23%23%20%E9%97%AE%E9%A2%98%E6%8E%92%E6%9F%A5%E8%BF%87%E7%A8%8B%E8%AE%B0%E5%BD%951%0A1.%20%E8%BF%87%E7%A8%8B1%0A%E7%9B%AE%E5%89%8Dlogstash%E5%AD%98%E5%9C%A8%E7%9A%84%E9%97%AE%E9%A2%98%E6%9C%89%0A%E7%8E%B0%E8%B1%A1%E6%9C%89%EF%BC%9A%0A(1)%E9%80%9A%E8%BF%87lvs%E4%BB%A3%E7%90%86%E7%9A%84%E5%A4%9A%E4%B8%AAlogstash%E5%8F%AA%E6%9C%89%E4%B8%80%E4%B8%AA%E8%8A%82%E7%82%B9%E5%9C%A8%E5%A4%84%E7%90%86%E6%95%B0%E6%8D%AE%0A(2)%E7%9B%B8%E5%90%8C%E6%9C%8D%E5%8A%A1%EF%BC%8C%E6%9C%89%E7%9A%84pod%E6%97%A5%E5%BF%97%E5%8F%AF%E4%BB%A5%E6%90%9C%E9%9B%86%E5%88%B0%EF%BC%8C%E6%9C%89%E7%9A%84%E6%90%9C%E4%B8%8D%E5%88%B0%EF%BC%8C%E4%B9%9F%E5%B0%B1%E6%98%AF%E6%9C%89%E7%9A%84filebeat%E6%97%A0%E6%B3%95%E5%8F%91%E9%80%81%E6%95%B0%E6%8D%AE%E5%88%B0logstash%0A%E9%97%AE%E9%A2%98%E6%9C%89%EF%BC%9A%0A(1)logstash%E5%90%AF%E5%8A%A8%E5%90%8E%EF%BC%8C%E4%B8%80%E4%BC%9A%E5%84%BF%E6%8A%A5%E9%94%99%22message%22%3A%22org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20message%20is%201679038%20bytes%20when%20serialized%20which%20is%20larger%20than%20the%20maximum%20request%20size%20you%20have%20configured%20with%20the%20max.request.size%20configuration.%0A%7B%22level%22%3A%22WARN%22%2C%22loggerName%22%3A%22logstash.outputs.kafka%22%2C%22timeMillis%22%3A1555085898245%2C%22thread%22%3A%22Ruby-0-Thread-6%40%5Bmain%5D%3Eworker0%3A%20%3A1%22%2C%22logEvent%22%3A%7B%22message%22%3A%22KafkaProducer.send()%20failed%3A%20org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20message%20is%201679038%20bytes%20when%20serialized%20which%20is%20larger%20than%20the%20maximum%20request%20size%20you%20have%20configured%20with%20the%20max.request.size%20configuration.%22%2C%22exception%22%3A%7B%22cause%22%3A%7B%22message%22%3A%22The%20message%20is%201679038%20bytes%20when%20serialized%20which%20is%20larger%20than%20the%20maximum%20request%20size%20you%20have%20configured%20with%20the%20max.request.size%20configuration.%22%2C%22localizedMessage%22%3A%22The%20message%20is%201679038%20bytes%20when%20serialized%20which%20is%20larger%20than%20the%20maximum%20request%20size%20you%20have%20configured%20with%20the%20max.request.size%20configuration.%22%7D%2C%22stackTrace%22%3A%5B%7B%22class%22%3A%22org.apache.kafka.clients.producer.KafkaProducer%24FutureFailure%22%2C%22method%22%3A%22%3Cinit%3E%22%2C%22file%22%3A%22org%2Fapache%2Fkafka%2Fclients%2Fproducer%2FKafkaProducer.java%22%2C%22line%22%3A1150%7D%2C%7B%22class%22%3A%22org.apache.kafka.clients.producer.KafkaProducer%22%2C%22method%22%3A%22doSend%22%2C%22file%22%3A%22org%2Fapache%2Fkafka%2Fclients%2Fproducer%2FKafkaProducer.java%22%2C%22line%22%3A846%7D%2C%7B%22class%22%3A%22org.apache.kafka.clients.producer.KafkaProducer%22%2C%22method%22%3A%22send%22%2C%22file%22%3A%22org%2Fapache%2Fkafka%2Fclients%2Fproducer%2FKafkaProducer.java%22%2C%22line%22%3A784%7D%2C%7B%22class%22%3A%22org.apache.kafka.clients.producer.KafkaProducer%22%2C%22method%22%3A%22send%22%2C%22file%22%3A%22org%2Fapache%2Fkafka%2Fclients%2Fproducer%2FKafkaProducer.java%22%2C%22line%22%3A671%7D%2C%7B%22class%22%3A%22java.lang.reflect.Method%22%2C%22method%22%3A%22invoke%22%2C%22file%22%3A%22java%2Flang%2Freflect%2FMethod.java%22%2C%22line%22%3A498%7D%2C%7B%22class%22%3A%22org.jruby.javasupport.JavaMethod%22%2C%22method%22%3A%22invokeDirectWithExceptionHandling%22%2C%22file%22%3A%22org%2Fjruby%2Fjavasupport%2FJavaMethod.java%22%2C%22line%22%3A453%7D%2C%7B%22class%22%3A%22org.jruby.javasupport.JavaMethod%22%2C%22method%22%3A%22invokeDirect%22%2C%22file%22%3A%22org%2Fjruby%2Fjavasupport%2FJavaMethod.java%22%2C%22line%22%3A314%7D%2C%7B%22class%22%3A%22usr.share.logstash.vendor.bundle.jruby.%242_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka%22%2C%22method%22%3A%22block%20in%20retrying_send%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Fvendor%2Fbundle%2Fjruby%2F2.3.0%2Fgems%2Flogstash-output-kafka-7.1.1%2Flib%2Flogstash%2Foutputs%2Fkafka.rb%22%2C%22line%22%3A253%7D%2C%7B%22class%22%3A%22org.jruby.RubyArray%22%2C%22method%22%3A%22collect%22%2C%22file%22%3A%22org%2Fjruby%2FRubyArray.java%22%2C%22line%22%3A2472%7D%2C%7B%22class%22%3A%22org.jruby.RubyArray%22%2C%22method%22%3A%22collect%22%2C%22file%22%3A%22org%2Fjruby%2FRubyArray.java%22%2C%22line%22%3A2481%7D%2C%7B%22class%22%3A%22usr.share.logstash.vendor.bundle.jruby.%242_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka%22%2C%22method%22%3A%22retrying_send%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Fvendor%2Fbundle%2Fjruby%2F2.3.0%2Fgems%2Flogstash-output-kafka-7.1.1%2Flib%2Flogstash%2Foutputs%2Fkafka.rb%22%2C%22line%22%3A250%7D%2C%7B%22class%22%3A%22usr.share.logstash.vendor.bundle.jruby.%242_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka%22%2C%22method%22%3A%22multi_receive%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Fvendor%2Fbundle%2Fjruby%2F2.3.0%2Fgems%2Flogstash-output-kafka-7.1.1%2Flib%2Flogstash%2Foutputs%2Fkafka.rb%22%2C%22line%22%3A226%7D%2C%7B%22class%22%3A%22org.jruby.RubyClass%22%2C%22method%22%3A%22finvoke%22%2C%22file%22%3A%22org%2Fjruby%2FRubyClass.java%22%2C%22line%22%3A908%7D%2C%7B%22class%22%3A%22org.jruby.RubyBasicObject%22%2C%22method%22%3A%22callMethod%22%2C%22file%22%3A%22org%2Fjruby%2FRubyBasicObject.java%22%2C%22line%22%3A363%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputStrategyExt%24SimpleAbstractOutputStrategyExt%22%2C%22method%22%3A%22doOutput%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputStrategyExt.java%22%2C%22line%22%3A219%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputStrategyExt%24SharedOutputStrategyExt%22%2C%22method%22%3A%22output%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputStrategyExt.java%22%2C%22line%22%3A247%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputStrategyExt%24AbstractOutputStrategyExt%22%2C%22method%22%3A%22multi_receive%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputStrategyExt.java%22%2C%22line%22%3A109%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputDelegatorExt%22%2C%22method%22%3A%22multi_receive%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputDelegatorExt.java%22%2C%22line%22%3A156%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22block%20in%20output_batch%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A475%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%2412%22%2C%22method%22%3A%22visit%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1362%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%2412%22%2C%22method%22%3A%22visit%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1359%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22visitLimited%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A662%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22visitAll%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A647%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22iteratorVisitAll%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1319%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22each_pairCommon%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1354%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22each%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1343%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22output_batch%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A474%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22worker_loop%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A426%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22RUBY%24method%24worker_loop%240%24__VARARGS__%22%2C%22file%22%3A%22usr%2Fshare%2Flogstash%2Flogstash_minus_core%2Flib%2Flogstash%2F%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A-1%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22block%20in%20start_workers%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A384%7D%2C%7B%22class%22%3A%22org.jruby.RubyProc%22%2C%22method%22%3A%22call%22%2C%22file%22%3A%22org%2Fjruby%2FRubyProc.java%22%2C%22line%22%3A289%7D%2C%7B%22class%22%3A%22org.jruby.RubyProc%22%2C%22method%22%3A%22call%22%2C%22file%22%3A%22org%2Fjruby%2FRubyProc.java%22%2C%22line%22%3A246%7D%2C%7B%22class%22%3A%22java.lang.Thread%22%2C%22method%22%3A%22run%22%2C%22file%22%3A%22java%2Flang%2FThread.java%22%2C%22line%22%3A748%7D%5D%2C%22message%22%3A%22org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20message%20is%201679038%20bytes%20when%20serialized%20which%20is%20larger%20than%20the%20maximum%20request%20size%20you%20have%20configured%20with%20the%20max.request.size%20configuration.%22%2C%22localizedMessage%22%3A%22org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20message%20is%201679038%20bytes%20when%20serialized%20which%20is%20larger%20than%20the%20maximum%20request%20size%20you%20have%20configured%20with%20the%20max.request.size%20configuration.%22%7D%7D%7D%0A(2)logstash%E5%90%AF%E5%8A%A8%E5%90%8E%EF%BC%8C%E4%B8%80%E4%BC%9A%E5%84%BF%E6%8A%A5%E9%94%99%22localizedMessage%22%3A%22org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20request%20included%20a%20message%20larger%20than%20the%20max%20message%20size%20the%20server%20will%20accept.%22%7D%7D%7D%0A%7B%22level%22%3A%22WARN%22%2C%22loggerName%22%3A%22logstash.outputs.kafka%22%2C%22timeMillis%22%3A1555087294303%2C%22thread%22%3A%22Ruby-0-Thread-6%40%5Bmain%5D%3Eworker0%3A%20%3A1%22%2C%22logEvent%22%3A%7B%22message%22%3A%22KafkaProducer.send()%20failed%3A%20org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20request%20included%20a%20message%20larger%20than%20the%20max%20message%20size%20the%20server%20will%20accept.%22%2C%22exception%22%3A%7B%22cause%22%3A%7B%22message%22%3A%22The%20request%20included%20a%20message%20larger%20than%20the%20max%20message%20size%20the%20server%20will%20accept.%22%2C%22localizedMessage%22%3A%22The%20request%20included%20a%20message%20larger%20than%20the%20max%20message%20size%20the%20server%20will%20accept.%22%7D%2C%22stackTrace%22%3A%5B%7B%22class%22%3A%22org.apache.kafka.clients.producer.internals.FutureRecordMetadata%22%2C%22method%22%3A%22valueOrError%22%2C%22file%22%3A%22org%2Fapache%2Fkafka%2Fclients%2Fproducer%2Finternals%2FFutureRecordMetadata.java%22%2C%22line%22%3A94%7D%2C%7B%22class%22%3A%22org.apache.kafka.clients.producer.internals.FutureRecordMetadata%22%2C%22method%22%3A%22get%22%2C%22file%22%3A%22org%2Fapache%2Fkafka%2Fclients%2Fproducer%2Finternals%2FFutureRecordMetadata.java%22%2C%22line%22%3A64%7D%2C%7B%22class%22%3A%22org.apache.kafka.clients.producer.internals.FutureRecordMetadata%22%2C%22method%22%3A%22get%22%2C%22file%22%3A%22org%2Fapache%2Fkafka%2Fclients%2Fproducer%2Finternals%2FFutureRecordMetadata.java%22%2C%22line%22%3A29%7D%2C%7B%22class%22%3A%22java.lang.reflect.Method%22%2C%22method%22%3A%22invoke%22%2C%22file%22%3A%22java%2Flang%2Freflect%2FMethod.java%22%2C%22line%22%3A498%7D%2C%7B%22class%22%3A%22org.jruby.javasupport.JavaMethod%22%2C%22method%22%3A%22invokeDirectWithExceptionHandling%22%2C%22file%22%3A%22org%2Fjruby%2Fjavasupport%2FJavaMethod.java%22%2C%22line%22%3A438%7D%2C%7B%22class%22%3A%22org.jruby.javasupport.JavaMethod%22%2C%22method%22%3A%22invokeDirect%22%2C%22file%22%3A%22org%2Fjruby%2Fjavasupport%2FJavaMethod.java%22%2C%22line%22%3A302%7D%2C%7B%22class%22%3A%22usr.share.logstash.vendor.bundle.jruby.%242_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka%22%2C%22method%22%3A%22block%20in%20retrying_send%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Fvendor%2Fbundle%2Fjruby%2F2.3.0%2Fgems%2Flogstash-output-kafka-7.1.1%2Flib%2Flogstash%2Foutputs%2Fkafka.rb%22%2C%22line%22%3A270%7D%2C%7B%22class%22%3A%22org.jruby.RubyEnumerable%24EachWithIndex%22%2C%22method%22%3A%22call%22%2C%22file%22%3A%22org%2Fjruby%2FRubyEnumerable.java%22%2C%22line%22%3A1003%7D%2C%7B%22class%22%3A%22org.jruby.RubyArray%22%2C%22method%22%3A%22each%22%2C%22file%22%3A%22org%2Fjruby%2FRubyArray.java%22%2C%22line%22%3A1734%7D%2C%7B%22class%22%3A%22org.jruby.RubyArray%24INVOKER%24i%240%240%24each%22%2C%22method%22%3A%22call%22%2C%22file%22%3A%22org%2Fjruby%2FRubyArray%24INVOKER%24i%240%240%24each.gen%22%2C%22line%22%3A-1%7D%2C%7B%22class%22%3A%22org.jruby.RubyClass%22%2C%22method%22%3A%22finvoke%22%2C%22file%22%3A%22org%2Fjruby%2FRubyClass.java%22%2C%22line%22%3A522%7D%2C%7B%22class%22%3A%22org.jruby.RubyEnumerable%22%2C%22method%22%3A%22callEach%22%2C%22file%22%3A%22org%2Fjruby%2FRubyEnumerable.java%22%2C%22line%22%3A140%7D%2C%7B%22class%22%3A%22org.jruby.RubyEnumerable%22%2C%22method%22%3A%22each_with_indexCommon%22%2C%22file%22%3A%22org%2Fjruby%2FRubyEnumerable.java%22%2C%22line%22%3A1037%7D%2C%7B%22class%22%3A%22org.jruby.RubyEnumerable%22%2C%22method%22%3A%22each_with_index%22%2C%22file%22%3A%22org%2Fjruby%2FRubyEnumerable.java%22%2C%22line%22%3A1067%7D%2C%7B%22class%22%3A%22usr.share.logstash.vendor.bundle.jruby.%242_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka%22%2C%22method%22%3A%22retrying_send%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Fvendor%2Fbundle%2Fjruby%2F2.3.0%2Fgems%2Flogstash-output-kafka-7.1.1%2Flib%2Flogstash%2Foutputs%2Fkafka.rb%22%2C%22line%22%3A268%7D%2C%7B%22class%22%3A%22usr.share.logstash.vendor.bundle.jruby.%242_dot_3_dot_0.gems.logstash_minus_output_minus_kafka_minus_7_dot_1_dot_1.lib.logstash.outputs.kafka%22%2C%22method%22%3A%22multi_receive%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Fvendor%2Fbundle%2Fjruby%2F2.3.0%2Fgems%2Flogstash-output-kafka-7.1.1%2Flib%2Flogstash%2Foutputs%2Fkafka.rb%22%2C%22line%22%3A226%7D%2C%7B%22class%22%3A%22org.jruby.RubyClass%22%2C%22method%22%3A%22finvoke%22%2C%22file%22%3A%22org%2Fjruby%2FRubyClass.java%22%2C%22line%22%3A908%7D%2C%7B%22class%22%3A%22org.jruby.RubyBasicObject%22%2C%22method%22%3A%22callMethod%22%2C%22file%22%3A%22org%2Fjruby%2FRubyBasicObject.java%22%2C%22line%22%3A363%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputStrategyExt%24SimpleAbstractOutputStrategyExt%22%2C%22method%22%3A%22doOutput%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputStrategyExt.java%22%2C%22line%22%3A219%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputStrategyExt%24SharedOutputStrategyExt%22%2C%22method%22%3A%22output%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputStrategyExt.java%22%2C%22line%22%3A247%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputStrategyExt%24AbstractOutputStrategyExt%22%2C%22method%22%3A%22multi_receive%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputStrategyExt.java%22%2C%22line%22%3A109%7D%2C%7B%22class%22%3A%22org.logstash.config.ir.compiler.OutputDelegatorExt%22%2C%22method%22%3A%22multi_receive%22%2C%22file%22%3A%22org%2Flogstash%2Fconfig%2Fir%2Fcompiler%2FOutputDelegatorExt.java%22%2C%22line%22%3A156%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22block%20in%20output_batch%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A475%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%2412%22%2C%22method%22%3A%22visit%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1362%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%2412%22%2C%22method%22%3A%22visit%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1359%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22visitLimited%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A662%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22visitAll%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A647%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22iteratorVisitAll%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1319%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22each_pairCommon%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1354%7D%2C%7B%22class%22%3A%22org.jruby.RubyHash%22%2C%22method%22%3A%22each%22%2C%22file%22%3A%22org%2Fjruby%2FRubyHash.java%22%2C%22line%22%3A1343%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22output_batch%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A474%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22worker_loop%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A426%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22RUBY%24method%24worker_loop%240%24__VARARGS__%22%2C%22file%22%3A%22usr%2Fshare%2Flogstash%2Flogstash_minus_core%2Flib%2Flogstash%2F%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A-1%7D%2C%7B%22class%22%3A%22usr.share.logstash.logstash_minus_core.lib.logstash.pipeline%22%2C%22method%22%3A%22block%20in%20start_workers%22%2C%22file%22%3A%22%2Fusr%2Fshare%2Flogstash%2Flogstash-core%2Flib%2Flogstash%2Fpipeline.rb%22%2C%22line%22%3A384%7D%2C%7B%22class%22%3A%22org.jruby.RubyProc%22%2C%22method%22%3A%22call%22%2C%22file%22%3A%22org%2Fjruby%2FRubyProc.java%22%2C%22line%22%3A289%7D%2C%7B%22class%22%3A%22org.jruby.RubyProc%22%2C%22method%22%3A%22call%22%2C%22file%22%3A%22org%2Fjruby%2FRubyProc.java%22%2C%22line%22%3A246%7D%2C%7B%22class%22%3A%22java.lang.Thread%22%2C%22method%22%3A%22run%22%2C%22file%22%3A%22java%2Flang%2FThread.java%22%2C%22line%22%3A748%7D%5D%2C%22message%22%3A%22org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20request%20included%20a%20message%20larger%20than%20the%20max%20message%20size%20the%20server%20will%20accept.%22%2C%22localizedMessage%22%3A%22org.apache.kafka.common.errors.RecordTooLargeException%3A%20The%20request%20included%20a%20message%20larger%20than%20the%20max%20message%20size%20the%20server%20will%20accept.%22%7D%7D%7D%0A%E8%A7%A3%E5%86%B3%E6%80%9D%E8%B7%AF%EF%BC%9A%0A(1)%E6%8E%92%E9%99%A4lvs%E7%9A%84%E5%BD%B1%E5%93%8D%EF%BC%8C%E7%94%B1filebeat%E7%9B%B4%E6%8E%A5%E8%BF%9E%E6%8E%A5logstash%E7%9A%84ip%E5%9C%B0%E5%9D%80%EF%BC%8C%0A%E6%9B%B4%E6%94%B9%E9%85%8D%E7%BD%AE%E7%94%B1hosts%3A%20’app-logs-k8s-sh.transfer.int.yidian-inc.com%3A5044%E2%80%99%20%E6%9B%B4%E6%94%B9%E4%B8%BA%0Ahosts%3A%20%5B%22172.19.2.238%3A5044%22%2C%20%22172.19.2.85%3A5044%22%2C%22172.19.5.23%3A5044%E2%80%9D%5D%0A%E5%8F%91%E7%8E%B0%E6%B2%A1%E4%BB%80%E4%B9%88%E4%BD%9C%E7%94%A8%0A%E5%B9%B6%E4%B8%94%E5%A4%9A%E6%AC%A1%E9%87%8D%E5%90%AFfilebeat%E5%8F%91%E7%8E%B0%E6%9C%89%E6%97%B6%E5%80%99%E5%B0%B1%E8%83%BD%E6%AD%A3%E5%B8%B8%E5%8F%91%E9%80%81%E6%97%A5%E5%BF%97%EF%BC%8C%E6%9C%89%E7%9A%84%E4%B8%8D%E8%83%BD%EF%BC%8C%E5%BE%88%E9%83%81%E9%97%B7%EF%BC%8C%E4%B8%8D%E6%96%AD%E5%9C%B0%E4%BF%AE%E6%94%B9filebeat%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%EF%BC%8C%E7%9B%B4%E5%88%B0%E7%AC%AC%E4%BA%8C%E5%A4%A9%E6%97%A9%E4%B8%8A%E6%97%A0%E6%84%8F%E4%B8%AD%E5%8F%91%E7%8E%B0%E6%9C%89%E4%B8%80%E4%B8%AAlogstash%E5%AE%9E%E4%BE%8B%E8%83%BD%E6%AD%A3%E5%B8%B8work%EF%BC%8C%E4%BD%86%E6%98%AF%E5%85%B6%E4%BB%96%E7%9A%84%E5%AE%9E%E4%BE%8B%E9%83%BD%E5%9C%A8%E6%8A%A5%E9%94%99%EF%BC%8C%E5%A6%82%E4%BB%A5%E4%B8%8A%E4%B8%A4%E4%B8%AA%E9%97%AE%E9%A2%98%0A(2)%E9%92%88%E5%AF%B9%E4%BA%8E%E9%97%AE%E9%A2%981%EF%BC%8Clogstash%20to%20kafka%E7%9A%84%E6%8F%92%E4%BB%B6%E9%85%8D%E7%BD%AE%E5%8F%82%E6%95%B0max_request_size%E9%BB%98%E8%AE%A4%E6%98%AF1048576%EF%BC%8C%E8%80%8Ckafka%E9%9B%86%E7%BE%A4%E4%B8%AD%E7%9A%84%E8%83%BD%E5%A4%84%E7%90%86%E7%9A%84%E6%B6%88%E6%81%AF%E6%9C%80%E5%A4%A7%E5%80%BC%E4%B8%BA8M%EF%BC%8Cmax.message.size%3D8388608%EF%BC%8C%E4%BA%8E%E6%98%AF%E8%B0%83%E6%95%B4%E5%8F%82%E6%95%B0max_request_size%20%3D%3E%208000000%0A(3)%E9%87%8D%E5%90%AFlogstash%E5%90%8E%E4%B8%80%E4%BC%9A%E5%84%BF%E5%8F%88%E6%8C%82%E4%BA%86%EF%BC%8C%E5%B9%B6%E6%8A%A5%E9%94%99(2)%2Ckafka%E7%9A%84%E5%8F%82%E6%95%B0%E4%B8%8D%E8%83%BD%E5%86%8D%E5%BE%80%E5%A4%A7%E7%9A%84%E8%B0%83%E6%95%B4%EF%BC%8C%E4%BD%86%E6%98%AF%E4%B8%80%E7%9B%B4%E5%8D%A1%E5%9C%A8%E4%BA%86%E8%BF%99%E9%87%8C%EF%BC%8C%E4%BA%8E%E6%98%AFretries%3D%3E10%20%2C%E5%B0%9D%E8%AF%9510%E6%AC%A1%EF%BC%8C%E5%A6%82%E6%9E%9C%E5%A4%B1%E8%B4%A5%E7%9A%84%E8%AF%9D%EF%BC%8C%E9%82%A3%E4%B9%88%E5%B0%B1%E8%B7%B3%E8%BF%87event%2C%E7%84%B6%E5%90%8E%E5%86%8D%E5%B0%86%E8%AF%A5%E5%8F%82%E6%95%B0%E5%88%A0%E9%99%A4%E3%80%82%E5%90%8C%E6%97%B6%E8%A7%82%E5%AF%9F%E5%88%B0filebeat%E4%B8%AD%E6%B6%88%E6%81%AF%E7%9A%84%E6%9C%80%E5%A4%A7%E5%80%BC%E6%98%AF10m%2C%E6%98%8E%E6%98%BEkafka%E9%9B%86%E7%BE%A4%E4%B8%8D%E8%83%BD%E5%A4%84%E7%90%86%EF%BC%8C%E6%89%80%E4%BB%A5%E4%BF%AE%E6%94%B9%E5%8F%82%E6%95%B0filebeat%E5%8F%82%E6%95%B0%E4%B8%BA1m%2C%20max_bytes%3A%201048576%2C%20%E6%A0%B9%E6%8D%AE%E6%8A%A5%E9%94%99%E4%BF%A1%E6%81%AF(1)%E8%B0%83%E6%95%B4logstash%E4%B8%80%E6%89%B9%E5%8F%91%E9%80%81%E6%95%B0%E6%8D%AE%E7%9A%84%E5%A4%A7%E5%B0%8F%E5%8F%82%E6%95%B0batch_size%E9%BB%98%E8%AE%A4%E6%98%AF16384%2Cbatch_size%20%3D%3E%2010000%2C%E7%84%B6%E5%90%8E%E9%87%8D%E5%90%AFlogstash%E5%8F%91%E7%8E%B0%E6%B2%A1%E9%97%AE%E9%A2%98%E4%BA%86%E3%80%82%0A%E6%9C%80%E7%BB%88filebeat%E7%9A%84%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%E4%B8%BA%EF%BC%9A%0A%60%60%60%0Afilebeat.inputs%3A%0A-%20type%3A%20log%0A%20%20enabled%3A%20true%0A%20%20paths%3A%0A%20%20-%20%2Flog%2F\ *%0A%20%20-%20%2Flog%2F*\ %2F\ *%0A%20%20-%20%2Flog%2F*\ %2F\ *%2F*\ %0A%20%20fields%3A%0A%20%20%20%20service%3A%20’%24%7BK8S_SERVICE%7D’%0A%20%20%20%20env%3A%20’%24%7BK8S_ENV%7D’%0A%20%20%20%20k8sNS%3A%20’%24%7BK8S_NAMESPACE%7D’%0A%20%20%20%20k8sCluster%3A%20’%24%7BK8S_CLUSTER%7D%E2%80%99%0A%20%20%23%E5%A4%84%E7%90%86%E5%8D%95%E6%9D%A1%E6%B6%88%E6%81%AF%E6%9C%80%E5%A4%A7%E5%80%BC%E4%B8%BA1m%20%0A%20%20max_bytes%3A%201048576%0A%20%20fields_under_root%3A%20true%0A%20%20exclude_files%3A%20%5B’%5C.gz%24’%5D%0A%23%20%E4%BB%8Eregistry%E6%96%87%E4%BB%B6%E4%B8%AD%E5%85%B3%E9%97%AD%E5%B7%B2%E7%BB%8F%E6%9B%B4%E6%94%B9%E5%90%8D%E5%AD%97%E7%9A%84%E6%96%87%E4%BB%B6%0Aclose_renamed%3A%20true%0A%23%20%E4%BB%8Eregistry%E6%96%87%E4%BB%B6%E4%B8%AD%E5%85%B3%E9%97%AD%E5%B7%B2%E7%BB%8F%E5%85%B3%E9%97%AD%E7%9A%84%E6%96%87%E4%BB%B6%0Aclose_removed%3A%20true%0A%23%20%E4%BB%8Eregistry%E6%96%87%E4%BB%B6%E4%B8%AD%E7%A7%BB%E9%99%A4%E5%B7%B2%E7%BB%8F%E5%85%B3%E9%97%AD%E7%9A%84%E6%96%87%E4%BB%B6%0Aclean_removed%3A%20true%0A%23%20%E4%B8%8D%E6%B4%BB%E8%B7%8348h%E5%B0%B1%E5%85%B3%E9%97%AD%0Aclose_inactive%3A%2048h%0Aignore_older%3A%2048h%0Aclean_inactive%3A%2072h%0Ascan_frequency%3A%203s%0Amultiline.max_lines%3A%2010%0Asetup.template.enabled%3A%20false%0Aoutput.logstash%3A%0A%20%20hosts%3A%20’app-logs-k8s-sh.transfer.int.yidian-inc.com%3A5044’%0A%20%20timeout%3A%2060%0A%23%E9%BB%98%E8%AE%A4%E7%BA%A7%E5%88%AB%E6%98%AFinfo%0Alogging.level%3A%20debug%0Alogstash%E7%9A%84%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%E4%B8%BA%EF%BC%9A%0Alogstash.conf%3A%20%7C-%0A%20%20%20%20input%20%7B%0A%20%20%20%20%20%20beats%20%7B%0A%20%20%20%20%20%20%20%20port%20%3D%3E%205044%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%20%20filter%20%7B%0A%20%20%20%20%20%20%20mutate%20%7B%0A%20%20%20%20%20%20%20%20%20%20%20remove_field%20%3D%3E%20%5B%20%22%40timestamp%22%2C%22%40metadata%22%2C%20%22%40version%22%2C%20%22offset%22%2C%20%22prospector%22%2C%20%22input%22%2C%20%22beat%22%2C%20%22tags%22%5D%0A%20%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%20%20output%20%7B%0A%20%20%20%20%20%20kafka%20%7B%0A%20%20%20%20%20%20%20%20%20bootstrap_servers%20%3D%3E%20%2210.120.11.25%3A9099%2C10.103.35.25%3A9099%2C10.103.187.35%3A9099%2C10.103.187.36%3A9099%2C10.103.33.176%3A9099%2C10.103.33.178%3A9099%2C10.103.33.180%3A9099%2C10.120.11.26%3A9099%2C10.120.11.27%3A9099%22%0A%20%20%20%20%20%20%20%20%20codec%20%3D%3E%20json%0A%20%20%20%20%20%20%20%20%20topic_id%20%3D%3E%20%20%22applog-sh-%25%7Bservice%7D-%25%7Benv%7D%22%0A%20%20%20%20%20%20%20%20%20max_request_size%20%3D%3E%208000000%0A%20%20%20%20%20%20%20%20%20batch_size%20%3D%3E%2010000%0A%20%20%20%20%20%20%20%20%20message_key%20%3D%3E%20%22%25%7B%5Bhost%5D%5Bname%5D%7D%22%0A%20%20%20%20%20%20%20%20%20acks%20%3D%3E%20%221%22%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%60%60%60%0A
