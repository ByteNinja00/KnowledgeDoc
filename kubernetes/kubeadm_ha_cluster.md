# kubeadm创建高可用集群
kubernetes以高效灵活的方式运行应用服务，已经成为云原生技术的核心引擎。
## 导航
<!-- top -->
- **[1. 集群资源](#1-集群资源)**
- **[2. 初始化集群环境](#2-初始化集群环境)**
    - **[2.1. 集群环境检查](#21-集群环境检查)**
- **[3. 安装容器运行时](#3-安装容器运行时)**
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
|HA-LB-A      |192.168.2.10 |2 Core|4 GiB  |40 GiB  |
|HA-LB-B      |192.168.2.20 |2 Core|4 GiB  |40 GiB  |

## 2. 初始化集群环境
> [!IMPORTANT]
> 初始化集群环境意味着运行kubernetes的每台主机都要执行一遍操作，确保每台主机符合集群预期规划。

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
                    - 223.5.5.5
                search: []
    version: 2
```

完成配置更新使用 `sudo netplan apply`，验证网络IP地址是否更改使用 `ip addr show` 查看。

> [!IMPORTANT]
> 编辑 `/etc/netplan/50-cloud-init.yaml` 网络配置文件时，按YAML缩进格式。否则会报语法错误。

- 设置主机名和网络地址映射
```
sudo tee -a /etc/hosts <<EOF

# kubernetes mapping
192.168.2.10  HA-LB-A
192.168.2.20  HA-LB-B
192.168.2.11  kube-master-1
192.168.2.12  kube-master-2
192.168.2.13  kube-master-3
192.168.2.21  kube-worker-1
192.168.2.22  kube-worker-2
192.168.2.23  kube-worker-3
EOF
```

> [!NOTE]
> 如果是克隆的虚拟机环境，需要把 *127.0.0.1* 对应的旧主机名替换为新主机名，如：*`127.0.0.1 template-vm`* 更改为 *`127.0.0.1 kube-master-1`*

### 2.1. 集群环境检查

- 节点主机MAC唯一性
```
ip link
```

- 节点主机UUID唯一性
```
sudo cat /sys/class/dmi/id/product_uuid
```

- 禁用交换分区
```
sudo sed -i '/^\/swap.img/d' /etc/fstab
```
> [!TIP]
> 卸载当前己挂载的交换分区使用 *`sudo swapoff --all`*
> 查看当前己挂载的交换分区使用 *`swapon --show`*

## 3. 安装容器运行时
