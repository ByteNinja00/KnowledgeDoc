# 分布式HADOOP集群布署

Hadoop 是 Apache 基金会的开源分布式计算框架，主要用于**存储和处理海量数据**。它通过“把大数据切成小块、分发到普通服务器上并行计算”来解决 PB 级数据的处理问题。

## 核心组件

Hadoop 主要由 **HDFS、YARN、MapReduce** 三大核心模块组成。

### 1. HDFS

HDFS（Hadoop Distributed <mark>File </mark>System，分布式文件系统，HDFS 解决的是 **海量数据存储**

- 目的：高吞吐、可扩展、高容错

- 数据以 block 形式存储（默认 128MB）

- 每个 block 有副本（默认 3 副本）

### 2. YARN

YARN（Yet Another Resource Negotiator），YARN 管理的是 **资源调度和任务管理**。

- ResourceManager（RM）管整个集群的资源。

- NodeManager（NM）管自己节点的资源和容器。

**YARN 是分布式集群的“操作系统”**，决定任务在哪台机器上跑。

### 3. MapReduce

MapReduce（分布式计算框架），MapReduce 是 Hadoop 最经典的计算模型（如今 Spark 更常用）。

- **Map**：将大数据切片 -> 并行处理

- **Reduce**：聚合结果

MapReduce 的优点：

- 容错强（节点挂了会自动重跑）

- 可在普通硬件上处理大数据

缺点：

- 速度慢（大量磁盘 IO）

- 编程复杂

## 一、集群布署

以下布署所有操作均在*Rocky 9.6*发行版下执行，集群3节点 ，符合生产实际可用最小集群，也适合学习测试环境。

| 主机名                 | IP地址           | 集群组件                     |
| ------------------- | -------------- | ------------------------ |
| hadoop.node.master  | 192.168.182.10 | NameNode、ResourceManager |
| hadoop.node.slave-1 | 192.168.182.11 | DataNode、NodeManager     |
| hadoop.node.slave-2 | 192.168.182.12 | DataNode、NodeManager     |
| hadoop.node.slave-3 | 192.168.182.13 | DataNode、NodeManager     |

- **设置主机名**（所有主机）

```bash
hostnamectl set-hostname hadoop.node.master
```

- **配置主机与IP映射**（所有节点）

```bash
192.168.182.10 hadoop.node.master    
192.168.182.11 hadoop.node.slave-1   
192.168.182.12 hadoop.node.slave-2   
192.168.182.13 hadoop.node.slave-3   
```

- **配置主机网卡IP地址**（所有节点）

```bash
[connection]
id=ens160
uuid=70e8db20-ce3e-3967-a938-6864382c7818
type=ethernet
autoconnect-priority=-999
interface-name=ens160
timestamp=1763169346

[ethernet]

[ipv4]
address1=192.168.182.10/24
dns=192.168.182.2;
gateway=192.168.182.2
may-fail=false
method=manual
```

> 配置生效：
> 
> 重载网络：`nmcli connection reload`  新地址生效：`nmcli device connect ens160`

- **关闭SElinux**（所有节点），需要重启

```bash
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```

- **关闭系统防火墙**

```bash
systemctl disable firewalld.service --now
```

- **配置集群时间同步（chronyd）**
  
  - 主节点
  
  ```bash
  pool ntp.aliyun.com iburst maxsources 2
  allow 192.168.182.0/24
  
  # 重启服务
  systemctl restart chronyd.service
  ```
  
  - 从节点
  
  ```bash
  pool hadoop.node.master iburst
  
  # 重启服务
  systemctl restart chronyd.service
  ```

- **创建hadoop集群用户**（所有节点）

```bash
useradd hadoop && echo "hadooppasswd" | passwd hadoop --stdin
```

```bash
# 格式化数据盘
mkfs.xfs /dev/nvme0n2
# 查找blkid
blkid /dev/nvme0n2
# 创建数据盘目录
mkdir /hadoop
# 在/etc/fstab添加开机自动挂载
UUID=$uuid /hadoop                 xfs     defaults        0 0
# 挂载当前数据目录
mount -a
# 修改数据目录所属用户为hadoop
chown -R hadoop:hadoop /hadoop
```

- **设置master到salve节点免密登陆**

```bash
cat /etc/hosts |awk '{print $2}'|grep -v localhost|sed '1d'|while read line; do ssh-copy-id hadoop@$line; done
```

## 二、安装JDK

hadoop集群的运行，需要JDK环境，hadoop对JDK版本支持，[官方WiKi](https://cwiki.apache.org/confluence/display/HADOOP/Hadoop+Java+Versions)也有介绍。以下所有节点均需要安装并配置。

[JDK官方下载地址](https://www.oracle.com/asean/java/technologies/downloads/#java8)

- 解压安装

```bash
tar zxvf jdk-8u471-linux-x64.tar.gz
```

## 三、安装HADOOP

Hadoop的安装包提供源码包和二进制包，这里以二进制包为布署方式，如果对定制化要求更高，建议对源码包进行编译。

Hadoop官方安装包下载地址：[HADOOP](https://hadoop.apache.org/docs/r3.3.6/)

- 解压安装

```bash
tar zxvf hadoop-3.3.6.tar.gz
```

## 四、设置环境变量

hadoop提供了环境变量文件以*xxx-env.sh或xxx-env.cmd*命名的方式让你设置，在本文教程因为所有的hadoop集群组件进程都以*hadoop*用户运行，所以只需要在`/home/hadoop/.bashrc`设置环境变理即可。

```bash
# Hadoop cluster env
export JAVA_HOME=/home/hadoop/jdk1.8.0_471
export HADOOP_HOME=/home/hadoop/hadoop-3.3.6
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

## 五、配置集群


