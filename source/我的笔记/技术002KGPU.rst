技术002KGPU

技术KGPU
========

[] 官方的GPU方案是容器独占的，不能实现共享。 解决思路有以下
思路1：“Model
Stuffing”，就是把多个机器学习应用跑在同一个容器里面，在容器里共享 GPU
资源。这是一种不得已而为之的做法 思路2：阿里云共享方案
思路3：vGPU，就是将GPU虚拟化。VMware 在 Kubernetes 中使用 vGPU
实现机器学习任务共享 GPU
