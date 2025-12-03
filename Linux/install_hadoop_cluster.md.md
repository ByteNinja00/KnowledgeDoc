# Hadoop分布式集群布署

Hadoop 是 Apache 基金会的开源分布式计算框架，主要用于**存储和处理海量数据**。它通过“把大数据切成小块、分发到普通服务器上并行计算”来解决 PB 级数据的处理问题。

## 核心组件

Hadoop 主要由 **HDFS、YARN、MapReduce** 三大核心模块组成。

### 1. HDFS

HDFS（Hadoop Distributed File System，分布式文件系统，HDFS 解决的是 **海量数据存储**。

- 主从架构：NameNode（主） + DataNode（从）

- 目的：高吞吐、可扩展、高容错

- 数据以 block 形式存储（默认 128MB）

- 每个 block 有副本（默认 3 副本）

### 2. YARN

YARN（Yet Another Resource Negotiator），YARN 管理的是 **资源调度和任务管理**。

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

### 环境准备

- 集群规划

| 主机名                 | IP地址           | 集群组件                                          |
| ------------------- | -------------- | --------------------------------------------- |
| node.master.hadoop  | 192.168.182.10 | NameNode、ResourceManager、DataNode、NodeManager |
| node.slave01.hadoop | 192.168.182.11 | DataNode、NodeManager、SecondaryNameNode       |
| node.slave02.hadoop | 192.168.182.12 | DataNode、NodeManager                          |

- 设置主机名（所有节点）

```bash
hostnamectl set-hostname node-master-hadoop
```

- 配置主机与IP映射（所有节点）

> 配置文件在`/etc/hosts`

```bash
192.168.182.10 node.master.hadoop
192.168.182.11 node.slave01.hadoop
192.168.182.12 node.slave02.hadoop
```

- 配置主机网卡IP地址（所有节点）

> 网卡配置文件在：`/etc/NetworkManager/system-connections/ens160.nmconnection`, 以node.master.hadoop为示例

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

重载网卡配置生效;

```bash
nmcli connection reload
nmcli device connect ens160
```

- 关闭SElinux（所有节点），需要重启。

> 编辑`/etc/selinux/config`配置文件如下所示

```bash
SELINUX=disabled
```

- 关闭防火墙

```bash
systemctl disable firewalld.service --now
```

- 配置集群时间同步（chronyd）

主节点:

```bash
pool ntp.aliyun.com iburst maxsources 2
allow 192.168.182.0/24

# 重启服务
systemctl restart chronyd.service
```

从节点：

```bash
pool node.master.hadoop iburst

# 重启服务
systemctl restart chronyd.service
```

- 创建运行hadoop集群用户（所有节点）

```bash
useradd hadoop
passwd hadoop
```

- 设置hadoop集群SSH免密登陆（只在master节点配置）

```bash
su hadoop
ssh-keygen -t ed25519
```

```bash
ssh-copy-id hadoop@node.master.hadoop
ssh-copy-id hadoop@node.slave01.hadoop
ssh-copy-id hadoop@node.slave02.hadoop
```

## 二、安装JDK

hadoop集群的运行，需要JDK环境，hadoop对JDK版本支持，[官方WiKi](https://cwiki.apache.org/confluence/display/HADOOP/Hadoop+Java+Versions)也有介绍。

[JDK官方下载地址](https://www.oracle.com/asean/java/technologies/downloads/#java8)

- 解压JDK压缩包（所有集群）

```bash
tar -zxvf jdk-8u471-linux-x64.tar.gz -C /usr/local/ && chown -R hadoop:hadoop /usr/local/jdk1.8.0_471
```

## 三、安装Hadoop

Hadoop的安装包提供源码包和二进制包，这里以二进制包为布署方式，如果对定制化要求更高，建议对源码包进行编译。

[Hadoop官方安装包下载地址]([Apache Hadoop](https://hadoop.apache.org/releases.html)

```bash
tar -zxvf hadoop-3.3.6.tar.gz -C /usr/local/ && chown -R hadoop:hadoop /usr/local/hadoop-3.3.6
```

## 四、配置集群

要成功启动hadoop集群，配置文件的正确配置是非常重要，以下是介绍各个配置文件的模块与功能。

- **core-site.xml**: 全局 Hadoop 配置（所有节点）;

这个文件用于配置Hadoop核心服务的相关信息，主要是HDFS和YARN所需的基本配置信息。

```xml
<configuration>
    <!-- HDFS 的访问地址（NameNode）-->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://node.master.hadoop:9000</value>
    </property>

    <!-- Hadoop 临时目录 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/hadoop/hdfs/tmp</value>
    </property>
</configuration>


```

- **hdfs-site.xml**: 配置HDFS集群；
  
  - `dfs.name.dir` 只在主机点(NameNode)上配置
  
  - `dfs.data.dir` 在从节点(DataNode)上配置

> 如果主节点上也配置`dfs.data.dir`则表明主节点同时也会作为DataNode角色

```xml
<configuration>
    <!-- 副本数量 -->
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>

    <!-- NameNode 存储目录 -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/hadoop/hdfs/namenode</value>
    </property>

    <!-- DataNode 存储目录 -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/hadoop/hdfs/datanode</value>
    </property>

    <!-- Web UI 端口（可默认） -->
    <property>
        <name>dfs.namenode.http-address</name>
        <value>node.master.hadoop:9870</value>
    </property>
</configuration>

```

**secondary namenode**：随便哪台，建议不要和NameNode在一起。

```xml
<property>
     <name>dfs.secondary.http.address</name>
     <value>node.slave01.hadoop:50090</value>
</property>

<!-- 设置 Secondary NameNode 的工作目录 -->
<property>
     <name>dfs.namenode.secondary.dir</name>
     <value>/data/hdfs/secondary</value> <!-- Secondary NameNode 存储 fsimage 和 edits 文件的位置 -->
</property>



```

- **yarn-site.xml**: 配置资源管理与调度，所有节点(RM、NM)；

虽然 ResourceManager 只在主节点上运行，但你需要在集群中的每台机器上配置 YARN，以确保每个 NodeManager 知道应该联系哪个 ResourceManager。

```xml
<property>
    <name>yarn.resourcemanager.hostname</name>
    <value>node.master.hadoop</value>
</property>


```

- **mapred-site.xml**: MapReduce配置（所有节点）

```xml
<configuration>
    <!-- 使用 YARN 作为 MapReduce 的执行框架 -->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

    <!-- 历史服务器 -->
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>node.master.hadoop:10020</value>
    </property>

    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>node.master.hadoop:19888</value>
    </property>
</configuration>


```

- **workers（或 slaves 文件）**；

用于告诉 Hadoop 哪些节点是 DataNode / NodeManager。

```xml
node.master.hadoop
node.slave01.hadoop
node.slave02.hadoop
```

- **hadoop-env.sh / yarn-env.sh / mapred-env.sh**: 各个模块的环境变量设置；

本文运行hadoop集群的用户为：`hadoop`，所以所有环境变量都在该用户下设置。

首先切换至`hadoop`用户：`su hadoop`，然后在`~/.bashrc`添加如下环境变量：

```bash
# hadoop-env.sh
export JAVA_HOME=/usr/local/jdk1.8.0_471
export HADOOP_HOME=/usr/local/hadoop-3.3.6
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

## 五、启动集群

在启动集群之前，必须格式化HDFS，这将初始化NameNode的元数据。

- 格式化HDFS（在主节点上）

```bash
hdfs namenode -format
```

- 启动HDFS集群

```bash
start-dfs.sh
```

- 启动YARN集群

```bash
start-yarn.sh
```

- 启动JHS节点

```bash
mapred --daemon start historyserver
```

## 六、WEB管理页面

| 类型              | WEB UI             | 端口    |
| --------------- | ------------------ | ----- |
| NameNode Web UI | node.master.hadoop | 9870  |
| JobHistory Web  | node.master.hadoop | 19888 |


