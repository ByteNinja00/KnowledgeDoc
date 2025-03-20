# kubeadm创建高可用集群
kubernetes以高效灵活的方式运行应用服务，已经成为云原生技术的核心引擎。
## 导航
<!-- top -->
- **[1. 集群资源](#1-集群资源)**
- **[2. 初始化集群环境](#2-初始化集群环境)**
    - **[2.1. 集群环境检查](#21-集群环境检查)**
- **[3. 安装容器运行时](#3-安装容器运行时)**
    - **[3.1. 安装Containerd](#31-安装containerd)**
    - **[3.2. 安装runc](#32-安装runc)**
    - **[3.3. 安装CNI插件](#33-安装cni插件)**
    - **[3.3. 配置Containerd](#34-配置containerd)**
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

最开始的K8s版本只支持Docker作为容器运行时，但为了更好与底层容器技术解耦（同时也是为了兼容其他容器技术），K8s 在v1.5.0就引入了容器运行时接口（CRI）。CRI是K8s与第三方容器运行时通信接口的标准化抽象，它定义了容器运行时必须实现的一组标准接口。

后来之所以K8s要宣称放弃Docker（在K8s v1.20）而选择container作为默认容器运行时，是因为Docker并不只是一个容器软件，而是一个完整的技术堆栈，它包含了许多除了容器软件基础功能以外的东西，这些东西不是K8s所需要的，而且增加K8s调度容器的性能开销。

如果在K8s v1.20及以后版本依然使用Docker作为容器运行时，需要安装配置一个叫做cri-dockerd的组件（作用类似docker-shim），它是一个轻量级的守护进程，用于将Docker请求转换为CRI请求。

### 3.1. 安装Containerd

kubernetes 1.24.x及以后版本默认CRI为containerd。安装containerd时自带的命令行工具是ctr，我们可以使用ctr 来直接管理containerd中的镜像或容器资源（包括由K8s间接管理的）。

> [!TIP]
> 由K8s间接管理的镜像和容器资源都存放在containerd中名为k8s.io 的命名空间下，例如你可以（在安装完集群后）通过ctr -n k8s.io c ls 查看K8s在当前节点调度的容器列表。

- 选择[下载](https://github.com/containerd/containerd/releases)二进制包

```
wget https://github.com/containerd/containerd/releases/download/v2.0.4/containerd-2.0.4-linux-amd64.tar.gz
```

- 安装
```
sudo tar zxvf containerd-2.0.4-linux-amd64.tar.gz -C /usr/local
```

- 创建Systemd服务
> [!NOTE]
> 配置文件路径在 */etc/systemd/system/containerd.service*

```
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target dbus.service

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
```

- 重载Systemd服务并设置为自启
```
sudo systemctl daemon-reload && sudo systemctl enable containerd.service --now
```
> [!NOTE]
> 查看服务状态使用: `systemctl stauts containerd.service`

### 3.2. 安装runc
runc 是一个根据 OCI 规范在 Linux 上生成和运行容器的 CLI 工具。

- [下载](https://github.com/opencontainers/runc/releases)官方二进制文件
```
wget https://github.com/opencontainers/runc/releases/download/v1.2.6/runc.amd64
```

- 安装
```
install -m 755 runc.amd64 /usr/local/sbin/runc
```
### 3.3. 安装CNI插件
CNI（容器网络接口）， 云原生计算基金会项目，由一个规范和库组成，用于编写插件来配置 Linux 和 Windows 容器中的网络接口，以及许多受支持的插件。CNI 只关注容器的网络连接以及在删除容器时删除分配的资源。

- [下载](https://github.com/containernetworking/plugins/releases)官方二进制
```
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz
```

- 安装
```
sudo mkdir -p /opt/cni/bin && sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz
```
### 3.4. 配置containerd
首先通过打印输出默认的配置文件重定向到 `/etc/containerd/config.toml` 。
```
sudo mkdir /etc/containerd && containerd config default | sudo tee /etc/containerd/config.toml
```