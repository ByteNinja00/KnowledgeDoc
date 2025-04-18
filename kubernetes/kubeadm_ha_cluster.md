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
- **[4. 安装Kubeadm套件](#4-安装kubeadm套件)**
- **[5. 时间同步服务](#5-时间同步服务)**
  - **[5.1. 服务端配置](#51-服务端配置)**
  - **[5.2. 客户端配置](#52-其它客户端配置)**
- **[6. 配置高可用负载均衡](#6-配置高可用负载均衡)**
  - **[6.1. 安装keepalived](#61-安装keepalived)**
  - **[6.2. 配置keepalived](#62-配置keepalived)**
  - **[6.3. 安装Nginx](#63-安装nginx)**
  - **[6.4. 配置Nginx](#64-配置nginx)**
- **[7. 初始化集群](#7-初始化集群)**
  - **[7.1. 初始化控制平面](#71-初始化控制平面)**

## 1. 集群资源
>
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
>
> [!IMPORTANT]
> 初始化集群环境意味着运行kubernetes的每台主机都要执行一遍操作，确保每台主机符合集群预期规划。

- 更新系统

```bash
sudo apt-get -y update && sudo apt-get -y upgrade
```

- 设置主机名

```bash
sudo hostnamectl set-hostname kube-master-1
```

- 设置主机网络

```yaml
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

```bash
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

- 开启网络转发

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
```

生效配置

```bash
sudo sysctl --system
```

验证生效

```bash
sysctl net.ipv4.ip_forward
```

> [!NOTE]
> 如果是克隆的虚拟机环境，需要把 *127.0.0.1* 对应的旧主机名替换为新主机名，如：*`127.0.0.1 template-vm`* 更改为 *`127.0.0.1 kube-master-1`*

### 2.1. 集群环境检查

- 节点主机MAC唯一性

```bash
ip link
```

- 节点主机UUID唯一性

```bash
sudo cat /sys/class/dmi/id/product_uuid
```

- 禁用交换分区

```bash
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

```bash
wget https://github.com/containerd/containerd/releases/download/v2.0.4/containerd-2.0.4-linux-amd64.tar.gz
```

- 安装

```bash
sudo tar zxvf containerd-2.0.4-linux-amd64.tar.gz -C /usr/local
```

- 创建Systemd服务

> [!NOTE]
> 配置文件路径在 */etc/systemd/system/containerd.service*

```bash
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

```bash
sudo systemctl daemon-reload && sudo systemctl enable containerd.service --now
```

> [!NOTE]
> 查看服务状态使用: `systemctl stauts containerd.service`

### 3.2. 安装runc

runc 是一个根据 OCI 规范在 Linux 上生成和运行容器的 CLI 工具。

- [下载](https://github.com/opencontainers/runc/releases)官方二进制文件

```bash
wget https://github.com/opencontainers/runc/releases/download/v1.2.6/runc.amd64
```

- 安装

```bash
install -m 755 runc.amd64 /usr/local/sbin/runc
```

### 3.3. 安装CNI插件

CNI（容器网络接口）， 云原生计算基金会项目，由一个规范和库组成，用于编写插件来配置 Linux 和 Windows 容器中的网络接口，以及许多受支持的插件。CNI 只关注容器的网络连接以及在删除容器时删除分配的资源。

- [下载](https://github.com/containernetworking/plugins/releases)官方二进制

```bash
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz
```

- 安装

```bash
sudo mkdir -p /opt/cni/bin && sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz
```

### 3.4. 配置containerd

首先通过打印输出默认的配置文件重定向到 `/etc/containerd/config.toml` 。

```bash
sudo mkdir /etc/containerd && containerd config default | sudo tee /etc/containerd/config.toml
```

- 在runc设置cgroup为systemd:

> [!TIP]
> Containerd有两个版本的配置文件格式：
>
> 1. x版本为version=2
> 2. x版本为version=3
>
> - 具体参考官方文档：[config.md](https://github.com/containerd/containerd/blob/main/docs/cri/config.md#cgroup-driver)

```bash
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
  SystemdCgroup = true
```

- 配置`pause`镜像:

```bash
[plugins.'io.containerd.cri.v1.images'.pinned_images]
      sandbox = 'registry.k8s.io/pause:3.10'
```

## 4. 安装Kubeadm套件

因为这里使用最新kubernetes版本(1.32)，如果要使用更早以前的版本，参考官方文档。
> [!IMPORTANT]
> kubeadm套件 `master节点需要全部安装`，`node节点只需要安装kubelet`

- 更新 apt 包索引并安装使用 Kubernetes apt 存储库所需的包：

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

- 下载 Kubernetes 软件包仓库的公共签名密钥。所有仓库都使用相同的签名密钥，因此可以忽略 URL 中的版本号：

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

- 添加1.32仓库:

```bash
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

- 更新 apt 包索引，安装 kubelet、kubeadm 和 kubectl，并固定它们的版本:

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

- (可选) 在运行 kubeadm 之前启用 kubelet 服务:

```bash
sudo systemctl enable --now kubelet
```

> [!TIP]
> 在集群没有引导安装之前kubelet服务一直会循环重启，这个现象属于正常。

## 5. 时间同步服务

- 安装chronyd时间同步服务:

```bash
sudo apt install chrony
```

### 5.1. 服务端配置

假设服务端主机IP为：192.168.2.10，那么其它客户端的时间同步源为：192.168.2.10

```bash
# 指定额外配置文件的目录，Chrony会加载该目录下的配置文件。
confdir /etc/chrony/conf.d

# 指定一个 NTP 服务器池：
# iburst：快速初始化时间同步，首次失败时快速发送请求包加速同步。
# maxsources 4：最多从4个服务器获取时间信息。
pool cn.ntp.org.cn iburst maxsources 4
pool ntp.aliyun.com iburst maxsources 2

# 指定动态配置文件目录，例如DHCP提供的NTP服务器信息。
sourcedir /run/chrony-dhcp

# 指定包含NTP源配置的目录，常用于分离式管理。
sourcedir /etc/chrony/sources.d

# 指定密钥文件路径，用于身份验证。
keyfile /etc/chrony/chrony.keys

# 存储时间漂移数据（drift 值），帮助 Chrony 调整硬件时钟的误差。
driftfile /var/lib/chrony/chrony.drift

# 存储NTS（Network Time Security）的相关信息。
ntsdumpdir /var/lib/chrony

# 启用日志记录的项目：
#                 tracking：记录本地时钟的跟踪统计信息。
#                 measurements：记录从各NTP源收到的测量值。
#                 statistics：记录统计信息。
log tracking measurements statistics

# 指定日志文件的存储目录。
logdir /var/log/chrony

# 定义允许的最大时间更新偏差（以毫秒为单位）。若偏差过大，Chrony将忽略该时间源。
maxupdateskew 100.0

# 启用实时时钟（RTC）的同步功能，确保系统关机后硬件时钟保持准确。
rtcsync

# 在启动或时间差异大于1秒时，立即校准时间（允许3次）。
makestep 1 3

# 配置闰秒的时区文件，通常是系统的 right/UTC。
leapsectz right/UTC

# 允许指定的IP范围访问Chrony服务，支持客户端同步时间。
allow 192.168.2.0/24

# 设置本地时钟为第10层时间源（Stratum 10），在没有其他上游服务器时作为后备时间源。
# 较高的层级（Stratum 10）避免其他NTP客户端优先使用本地时钟。
local stratum 10
```

### 5.2. 其它客户端配置

因为之前设置服务端为其它客户端的时钟源，所以集群内所有作为客户端的主机同步的时源都为：*192.168.2.10*。

```bash
pool 192.168.2.10 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony/chrony.keys
leapsectz right/UTC
log tracking measurements statistics
logdir /var/log/chrony
```

## 6. 配置高可用负载均衡

在设置生产集群时，高可用性（即使某些控制平面或工作节点发生故障，集群仍能保持正常运行的能力）通常是一项要求。对于工作节点，假设它们数量足够多，高可用性是集群本身的功能之一。

> [!NOTE]
> 官方文档中推荐使用[HAproxy+keepalived](https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#high-availability-considerations)作为高可用的解决方案。
> 但是本文使用 **nginx+keepalived** 作为高可用解决方案。

### 6.1. 安装keepalived

keepalived服务提供了一个由可配置健康检查管理的虚拟 IP。由于虚拟 IP 的实现方式，所有协商虚拟 IP 的主机都需要位于同一 IP 子网中。

```bash
sudo apt-get -y install keepalived
```

### 6.2. 配置keepalived

- MASTER配置

```bash
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
    router_id HA-LB-1
}

vrrp_script check_apiserver {
        script "/etc/keepalived/check_apiserver.sh"
        interval 3
        weight -2
        fall 3
        rise 2
}

vrrp_instance VT_1 {
        state MASTER
        interface enp1s0
        virtual_router_id 51
        priority 100
        advert_int 1
        authentication {
                auth_type PASS
                auth_pass 1111
        }
        virtual_ipaddress {
                192.168.2.100
        }
        track_script {
        check_apiserver
      }
}
```

- BACKUP配置

```bash

! /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
    router_id HA-LB-2
}

vrrp_script check_apiserver {
        script "/etc/keepalived/check_apiserver.sh"
        interval 3
        weight -2
        fall 3
        rise 2
}

vrrp_instance VT_1 {
        state BACKUP
        interface enp1s0
        virtual_router_id 51
        priority 98
        advert_int 1
        authentication {
                auth_type PASS
                auth_pass 1111
        }
        virtual_ipaddress {
                192.168.2.200
        }
        track_script {
        check_apiserver
  }
}
```

- check_apiserver.sh 检查脚本

```bash
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl -sfk --max-time 2 https://localhost:16443/healthz -o /dev/null || errorExit "Error GET https://localhost:16443/healthz"

```

### 6.3. 安装Nginx

```bash
sudo apt-get -y install nginx nginx-full
```

### 6.4. 配置Nginx

配置中server字段为 api-server服务的地址和端口号。

```c
stream {
        log_format proxy_log '$remote_addr [$time_local] $protocol $status $bytes_sent $bytes_received $session_time';
        upstream k8s-apiserver {
                server 192.168.2.11:6443;
                server 192.168.2.12:6443;
                server 192.168.2.13:6443;
        }

        server {
                listen 16443;
                proxy_pass k8s-apiserver;
                access_log /var/log/nginx/k8s-apiserver-access.log proxy_log;
                error_log /var/log/nginx/k8s-apiserver-error.log;
        }
}
```

> [!TIP]
> 配置完成之后，启动服务：`sudo systemctl enable nginx --now`。
> 之后使用：`sudo ss -tnlp` 查看16443端口是否己经处于监听状态。

## 7. 初始化集群

本节master节点架构属于堆叠，也就是所有控制平面的组件和ETCD都在同一台主机上。

### 7.1. 初始化控制平面

这里使用的是声明式创建，就是提供一份初始化清单(yaml格式)的文件

```yaml
apiVersion: kubeadm.k8s.io/v1beta4
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 1.2.3.4
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  imagePullSerial: true
  name: node
  taints: null
timeouts:
  controlPlaneComponentHealthCheck: 4m0s
  discovery: 5m0s
  etcdAPICall: 2m0s
  kubeletHealthCheck: 4m0s
  kubernetesAPICall: 1m0s
  tlsBootstrap: 5m0s
  upgradeManifests: 5m0s
---
apiServer: {}
apiVersion: kubeadm.k8s.io/v1beta4
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: 1.32.0
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
proxy: {}
scheduler: {}
```

> [!TIP]
> 使用 `kubeadm config print init-defaults > init-defaults.yaml`, 然后再修改配置文件为合适的内容。