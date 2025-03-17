# kubeadm创建高可用集群
kubernetes以高效灵活的方式运行应用服务，已经成为云原生技术的核心引擎。
## 目录
<!-- top -->
- [1. 集群资源](#1-集群资源)

## 1. 集群资源
>[!NOTE]
>本文运行kubernetes集群的所有机器操作系统均为 **Ubuntu 24.04**

|主机名       |IPv4网络地址|CPU核心|内存容器|磁盘容量|
|:------------|:----------|:-----|:------|:-------|
|kube-master-1|10.17.2.11 |2 Core|4 GiB  |40 GiB  |
|kube-master-2|10.17.2.12 |2 Core|4 GiB  |40 GiB  |
|kube-master-3|10.17.2.13 |2 Core|4 GiB  |40 GiB  |
|kube-worker-1|10.17.2.21 |4 Core|8 GiB  |80 GiB  |
|kube-worker-2|10.17.2.22 |4 Core|8 GiB  |80 GiB  |
|kube-worker-3|10.17.2.23 |4 Core|8 GiB  |80 GiB  |
|ha-lb-1      |10.17.2.10 |2 Core|4 GiB  |40 GiB  |
|ha-lb-2      |10.17.2.20 |2 Core|4 GiB  |40 GiB  |

## 2. 初始化集群环境
- 更新系统
```
sudo apt-get -y update && sudo apt-get -y upgrade
```
- 设置主机名
```
sudo hostnamectl set-hostname kube-master-1
```
> [!NOTE]
> 退出重新登陆。
> 所有节点主机均应设置主机名，方法同上。