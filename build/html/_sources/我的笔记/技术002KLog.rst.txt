技术002KLog

技术002KLog
===========

[]

日志级别
--------

journalctl -xefu kubelet的日志级别 –v=0 Generally useful for this to
ALWAYS be visible to an operator. –v=1 A reasonable default log level if
you don’t want verbosity.

–v=2 Useful steady state information about the service and important log
messages that may correlate to significant changes in the system. This
is the recommended default log level for most systems.

–v=3 Extended information about changes. –v=4 Debug level verbosity.
–v=6 Display requested resources. –v=7 Display HTTP request headers.
–v=8 Display HTTP request contents. –v=9 Display HTTP request contents
without truncation of contents.

日志搜集方案
------------

-  云原生日志方案

https://juejin.im/post/5b6eaef96fb9a04fa25a0d37

-  小米

https://mp.weixin.qq.com/s/iBQzN3DtIPa3wZ96d5Uvng
Prometheus监控Kubernetes系列1——监控框架
https://mp.weixin.qq.com/s/rG1_DqjBjisuhQJNi9U7iA
Prometheus监控Kubernetes系列2——监控部署
https://mp.weixin.qq.com/s/l0yWzLMC4KFNkFwjtDZOeQ
Prometheus监控Kubernetes系列3——业务指标采集
