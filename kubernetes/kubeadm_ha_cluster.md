# kubeadm创建高可用集群
kubernetes以高效灵活的方式运行应用服务，已经成为云原生技术的核心引擎。
## 导航
<!-- top -->
- **[1. 集群资源](#1-集群资源)**
- **[2. 初始化集群环境](#2-初始化集群环境)**

## 1. 集群资源
>[!NOTE]
>本文运行kubernetes集群的所有机器操作系统均为 **Ubuntu 24.04**

|主机名       |IPv4网络地址|CPU核心|内存容器|磁盘容量|
|:------------|:----------|:-----|:------|:-------|
|kube-master-1|192.168.2.11|2 Core|4 GiB  |40 GiB  |
|kube-master-2|192.168.2.12 |2 Core|4 GiB  |40 GiB  |
|kube-master-3|192.168.2.13 |2 Core|4 GiB  |40 GiB  |
|kube-worker-1|192.168.2.21 |4 Core|8 GiB  |80 GiB  |
|kube-worker-2|192.168.2.22 |4 Core|8 GiB  |80 GiB  |
|kube-worker-3|192.168.2.23 |4 Core|8 GiB  |80 GiB  |
|ha-lb-1      |192.168.2.10 |2 Core|4 GiB  |40 GiB  |
|ha-lb-2      |192.168.2.20 |2 Core|4 GiB  |40 GiB  |

## 2. 初始化集群环境
> [!IMPORTANT]
> 初始化集群环境意味着每台主机都要执行一遍操作，确保每台主机符合集群预期规划。

- 更新系统
```
sudo apt-get -y update && sudo apt-get -y upgrade
```
- 设置主机名
```
sudo hostnamectl set-hostname kube-master-1
```

- 设置主机网络

```
network:
    ethernetes:
        enp1s0:
            dhcp4: false
            addresses:
                - 192.168.2.10
            routes:
                - to: default
                  via: 192.168.2.1
            nameservers:
                addresses:
                    - 192.168.2.1
                    - 225.3.3.3
                search: []
    version: 2
```

完成配置更新使用 `sudo netplan apply`，验证网络IP地址是否更改使用 `ip addr show` 查看。

> [!IMPORTANT]
> 编辑 `/etc/netplan/50-cloud-init.yaml` 网络配置文件时，按YAML缩进格式。否则会报语法错误。