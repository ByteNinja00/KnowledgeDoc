# Hadoop分布式集群布署

Hadoop 是 Apache 基金会的开源分布式计算框架，主要用于**存储和处理海量数据**。它通过“把大数据切成小块、分发到普通服务器上并行计算”来解决 PB 级数据的处理问题。

## 核心组件

Hadoop 主要由 **HDFS、YARN、MapReduce** 三大核心模块组成。

### 1. HDFS

HDFS（Hadoop Distributed File System，分布式文件系统，HDFS 解决的是 **海量数据存储**

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

## 1. 集群资源规划

以下布署所有操作均在*Rocky 9.6*发行版下执行，集群5个节点，其中有2台需要做HA故障切换，其余3台均为**DataNode**节点。

| NodeName      | IPaddress      | HDFS                       | YARN            |
| ------------- | -------------- | -------------------------- | --------------- |
| node-master-1 | 192.168.182.10 | NameNode                   | ResourceManager |
| node-slave-1  | 192.168.182.21 | DataNode                   | NodeManager     |
| node-slave-2  | 192.168.182.22 | DataNode                   | NodeManager     |
| node-slave-3  | 192.168.182.23 | DataNode、SecondaryNameNode | NodeManager     |

## 2. 前置准备

在布署Hadoop集群前，需要做一些环境配置，比如设置主机名、配置集群NTP时间同步之类这些必要的环境初始化工作。

### 2.1. 设置主机名

```bash
hostnamectl set-hostname node-master-1
```

### 2.2. 主机名映射

在所有节点上设置主机与IP之间的映射，方便之后主机名之间的解析。

```bash
192.168.182.10  node-master-1
192.168.182.21  node-slave-1
192.168.182.22  node-slave-2
192.168.182.23  node-slave-3
```

### 2.3. 配置网卡

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

> 通过`uuidgen`生成新的*uuid*值，替换配置文件内*uuid*的值。

### 2.4. 重载网卡配置文件

```bash
nmcli connection reload
```

### 2.5. 关闭SElinux

```bash
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```

### 2.6. 关闭防火墙

```bash
systemctl disable firewalld.service --now
```

### 2.7. 配置集群NTP

- 主节点
  
  ```bash
  pool ntp.aliyun.com iburst maxsources 2
  allow 192.168.182.0/24
  ```

- 从节点
  
  ```bash
  pool node-master-1 iburst
  ```

重启服务：

```bash
systemctl restart chronyd.service
```

### 2.8. 创建Hadoop集群用户

```bash
useradd hadoop && echo "hadooppasswd" | passwd hadoop --stdin
```

### 2.9. 挂载数据盘

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

### 2.10. 设置主机之间免密登陆

```bash
cat /etc/hosts |awk '{print $2}'|grep -v localhost|sed '1d'|while read line; do ssh-copy-id hadoop@$line; done
```

配置主机之间免密登陆目的，是集群级别启动时，从master主机使用如`start-dfs.sh` 、`start-yarn.sh` 之类的集群启动脚本不需要交互式输入密码。

## 3. 安装JDK

hadoop集群的运行，需要JDK环境，hadoop对JDK版本支持，[官方WiKi](https://cwiki.apache.org/confluence/display/HADOOP/Hadoop+Java+Versions)也有介绍。以下所有节点均需要安装并配置。

[JDK官方下载地址](https://www.oracle.com/asean/java/technologies/downloads/#java8)

- 切换至hadoop用户

```bash
su hadoop
```

- 解压安装

```bash
tar zxvf jdk-8u471-linux-x64.tar.gz -C /hadoop
```

## 4. 安装HADOOP

Hadoop的安装包提供源码包和二进制包，这里以二进制包为布署方式，如果对定制化要求更高，建议对源码包进行编译。

Hadoop官方安装包下载地址：[HADOOP](https://hadoop.apache.org/docs/r3.3.6/)

```bash
tar zxvf hadoop-3.3.6.tar.gz -C /hadoop
```

## 5. 集群配置

配置文件目录: *$HADOOP_HOME/etc/hadoop* 在这个目录下存储着hadoop集群的配置文件。

### 5.1. hadoop-env.sh

这个配置文件主要控制Hadoop运行时的环境变量，确保环境变量配置文件有以下内容：

```bash
export JAVA_HOME=/hadoop/jdk1.8.0_471
export HADOOP_HOME=/hadoop/hadoop-3.3.6
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

然后在hadoop用户~/.bashrc文件下加入如下内容：

```bash
source $HADOOP_HOME/etc/hadoop/hadoop-env.sh
```

### 5.2. **core-site.xml**

配置Hadoop的基本信息，确保所有节点都能够访问到HDFS。打开`core-site.xml`，添加如下配置：

```xml
<configuration>
<!-- 设置默认的文件系统为HDFS，指定NameNode的地址 -->
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://node-master-1:9000</value> <!-- 主节点的hostname和端口 -->
  </property>

  <!-- 设置为一个用户，通常为hadoop，用于访问Web UI -->
  <property>
    <name>hadoop.http.staticuser.user</name>
    <value>hadoop</value>
  </property>
</configuration>


```

### 5.3. hdfs-site.xml

配置HDFS的存储目录、复制因子以及块大小等参数。

```xml
<configuration>
  <!-- 设置HDFS的副本数量。小型集群通常设置为3，确保数据有冗余 -->
  <property>
    <name>dfs.replication</name>
    <value>3</value>  <!-- 3个副本，保证数据冗余 -->
  </property>

  <!-- 设置NameNode的存储目录，用于存储HDFS元数据 -->
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///hadoop/hdfs/namenode</value>  <!-- NameNode的存储目录 -->
  </property>

  <!-- 设置DataNode的存储目录，用于存储HDFS数据块 -->
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///hadoop/hdfs/datanode</value>  <!-- DataNode的存储目录 -->
  </property>

  <!-- 设置HDFS的块大小。128MB块大小是常见的设置，适用于大部分场景 -->
  <property>
    <name>dfs.block.size</name>
    <value>134217728</value>  <!-- 128MB的块大小 -->
  </property>

  <!-- 设置 Web UI 端口 -->
  <property>
    <name>dfs.namenode.http-address</name>
    <value>node-master-1:50070</value>  <!-- 默认的Web UI地址和端口 -->
  </property>

  <!-- SecondaryNameNode的HTTP地址 -->
  <property>
    <name>dfs.secondary.http.address</name>
    <value>node-slave-3:50090</value>
  </property>
</configuration>


```

### 5.4. yarn-site.xml

配置YARN的资源管理器（ResourceManager）和节点管理器（NodeManager）。

```xml
<configuration>
  <!-- 设置ResourceManager的主机名，这样YARN知道在哪里找到资源管理器 -->
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>node-master-1</value>  <!-- ResourceManager所在的主节点 -->
  </property>

  <!-- 设置NodeManager使用MapReduce的Shuffle服务 -->
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>  <!-- 启用MapReduce Shuffle服务 -->
  </property>

  <!-- 设置每个NodeManager最多可以使用的内存 -->
  <property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>4096</value>  <!-- 每个NodeManager最多使用4GB内存 -->
  </property>

  <!-- 设置每个NodeManager最多可以使用的CPU核数 -->
  <property>
    <name>yarn.nodemanager.resource.cpu-vcores</name>
    <value>2</value>  <!-- 每个NodeManager最多使用2个CPU核 -->
  </property>

  <!-- 设置每个任务可以分配的最大内存 -->
  <property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>2048</value>  <!-- 每个任务最多分配2GB内存 -->
  </property>

  <!-- 设置每个任务可以分配的最大CPU核数 -->
  <property>
    <name>yarn.scheduler.maximum-allocation-vcores</name>
    <value>1</value>  <!-- 每个任务最多分配1个CPU核 -->
  </property>

  <!-- YARN ResourceManager Web UI的地址，通常是ResourceManager所在的节点的8088端口 -->
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>node-master-1:8088</value>  <!-- ResourceManager Web UI的地址 -->
  </property>
</configuration>
```

### 5.5. mapred-site.xml

配置MapReduce框架，告诉YARN使用MapReduce作为计算框架。

```xml
<configuration>
  <!-- 配置MapReduce使用YARN作为执行框架 -->
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>  <!-- 设置为YARN来运行MapReduce任务 -->
  </property>
  
  <!-- 配置MapReduce作业历史记录的Web UI地址 -->
  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>node-master-1:19888</value>  <!-- MapReduce历史记录Web UI -->
  </property>
</configuration>


```

### 5.6. master

配置Hadoop的Master节点，指定哪个节点负责管理NameNode和ResourceManager。

```bash
node-master-1
```

### 5.7. slaves

配置Hadoop的Slave节点，指定所有从节点（DataNode和NodeManager）。

```bash
node-slave-1
node-slave-2
node-slave-3
```

## 6. 分发集群配置

```bash
file_array=("hadoop-env.sh" "core-site.xml" "hdfs-site.xml" "yarn-site.xml" "mapred-site.xml" "master" "workers")
host_array=("node-slave-1" "node-slave-2" "node-slave-3")
for host in ${host_array[@]}; do for file in ${file_array[@]}; do scp /hadoop/hadoop-3.3.6/etc/hadoop/$file hadoop@$host:/hadoop/hadoop-3.3.6/etc/hadoop/; done; done
```

## 7. 启动集群

集群启动的顺序很关键，第一次一定要对namenode的元数据进行一次格式化，然后启动hdfs->yarn

- 格式化hdfs:

```bash
hdfs namenode -format
```

- 启动HDFS

```bash
start-dfs.sh
```

- 启动 YARN

```bash
start-yarn.sh
```

- 启动历史服务器

```bash
mapred --daemon start historyserver
```

## 8. WEB UI 地址

| 服务         | 地址                          |
| ---------- | --------------------------- |
| NameNode   | http://192.168.182.10:50070 |
| YARN       | http://192.168.182.10:8088  |
| JobHistory | http://192.168.182.10:19888 |


