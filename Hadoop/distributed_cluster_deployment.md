# Hadoop分布式集群的布署

Hadoop 是一个开源的分布式计算框架，旨在处理大规模数据集。它能够将数据存储和处理的任务分布到多个计算节点上，能够让用户高效地存储、处理和分析非常庞大的数据。

## 1. 组件的构成

- **HDFS (Hadoop Distributed File System)：** HDFS 是 Hadoop 的分布式文件系统，用于存储大数据。它能够将文件分成小块（称为块，通常大小为 128MB 或 256MB）并将它们分布在多个服务器上。它非常适合大规模的数据存储需求，并且具有高容错性，因为它会将数据副本存储在不同的机器上。

- **YARN (Yet Another Resource Negotiator)：** YARN 是 Hadoop 的资源管理和调度框架，它负责在集群中管理计算资源，并协调不同应用程序的任务。通过 YARN，Hadoop 可以运行多个不同的计算框架，如 MapReduce、Spark 等。

- **MapReduce：** MapReduce 是 Hadoop 的计算模型，它将任务分为两个阶段：
  
  - Map 阶段：将输入数据分割成小块，并对每个小块进行处理，生成中间结果。
  
  - Reduce 阶段：将中间结果合并和聚合，生成最终输出。
  
  这个过程可以并行化，从而提高计算效率。

## 2. 生态圈

Hadoop 生态圈通常指围绕 **Hadoop 分布式存储与计算框架** 构建的一整套大数据组件体系，覆盖 **数据采集、存储、计算、资源管理、查询分析、调度、治理与运维** 等多个层面。

### 2.1. 数据计算与处理引擎

- Spark：内存计算框架，速度远超 MapReduce

- Flink：常用于实时指标、实时风控、日志处理

### 2.2. SQL 与数据仓库工具

- Hive：基于 HDFS 的数据仓库工具

- Impala：MPP 架构的交互式 SQL 引擎

### 2.3. 数据存储（非 HDFS）

- HBase：分布式列式 NoSQL 数据库

- Kudu：介于 HDFS 与 HBase 之间

### 2.4. 数据采集与消息系统

- Kafka：分布式消息队列，常作为 Flink / Spark Streaming 数据源

- Flume：日志采集工具

> [!NOTE]
> 
> Hadoop的生态圈很庞大，以上只是列出部份，所有这些都依赖核心集群hadoop。

## 3. 集群规划

本文以4个节点布署一个完全分布式的hadoop集群，其中每台主机运行的组件如下：

| HostName       | IPAddress      | HDFS                      | YARN            |
| -------------- | -------------- | ------------------------- | --------------- |
| node-manager-1 | 192.168.135.11 | NameNode                  | ResourceManager |
| node-worker-1  | 192.168.135.22 | DataNode                  | NodeManager     |
| node-worker-2  | 192.168.135.22 | DataNode                  | NodeManager     |
| node-worker-3  | 192.168.135.23 | DataNode、Standby NameNode | NodeManager     |

## 4. 环境准备

运行hadoop集群需要对每台机器作一些配置，如：配置主机名和IP地址映射、主机之间免密登陆、安装JDK等。

### 4.1. 配置hosts

在`/etc/hosts`添加需要做主机名IP映射的列表：

```bash
192.168.135.11  node-manager-1
192.168.135.21  node-worker-1
192.168.135.22  node-worker-2
192.168.135.23  node-worker-3
```

### 4.2. 安装JDK

因为Hadoop是由JAVA编写的，运行Hadoop集群需要JAVA运行环境，参考[官方下载地址]([Java Downloads | Oracle](https://www.oracle.com/java/technologies/downloads/#java8-linux))。

- 解压安装

```bash
tar zxvf jdk-8u471-linux-x64.tar.gz -C /hadoop/src/
```

- 创建`hadoop`用户

```bash
useradd hadoop
```

- 设置`hadoop`密码

```bash
passwd hadoop
```

- 切换到`hadoop`用户

```bash
su hadoop
```

- 设置用户环境变量

```bash
export JAVA_HOME=/hadoop/src/jdk1.8.0_471
export PATH=$PATH:$JAVA_HOME/bin
```

> [!NOTE]
> 
> 用户环境变量文件路径：`/home/hadoop/.bashrc`

- 使当前环境变量生效

```bash
source /home/hadoop/.bashrc
```

### 4.3. 安装Hadoop

Hadoop官方二进制[下载地址](https://hadoop.apache.org/releases.html)，二进制文件直接解压到指定目录下可以直接运行。

- 解压安装

```bash
tar -zxvf hadoop-3.3.6.tar.gz -C /hadoop/src/
```

- 设置用户环境变量

```bash
export JAVA_HOME=/hadoop/src/jdk1.8.0_471
export HADOOP_HOME=/hadoop/src/hadoop-3.3.6
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

> [!NOTE]
> 
> 可以看出用户环境变量配置文件和JAVA的大致相同，只需要在配置JAVA环境变量的基础之上添加。

- 使当前环境变量生效

```bash
source /home/hadoop/.bashrc
```

### 4.4. 配置主机免密登陆

配置主机之间免密互信是为了后续能批量的管理集群，如比分发集群配置文件，使用hadoop内置的集群管理命令。

> [!NOTE]
> 
> 管理集群主要是在管理节点上(node-manager-1)，配置文件的修改，然后分发到其它工作节点，集群的启动，需要登陆到工作节点执行命令。

- 生成SSH密钥对文件

```bash
ssh-keygen -t ed25519
```

- 将公钥远程拷贝到基它主机

```bash
cat /etc/hosts | grep node|grep -v node-manager-1|awk '{print $2}'|while read line; do ssh-copy-id hadoop@$line; done
```

### 4.5. 关闭firewalld

关闭firewalld要用root用户：

```bash
systemctl disable firewalld.service --now
```

### 4.6. 关闭SElinux

关闭SElinux同样也要用到root用户:

```bash
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
```

### 4.7. 配置时间同步

分布式集群对时间是比较敏感的，集群内时间同步是非常重要。本文使用chronyd作为时间同步服务，配置文件在：`/etc/chrony.conf`

- 管理节点

```bash
pool cn.ntp.org.cn iburst maxsources 4
pool ntp.aliyun.com iburst maxsources 2

allow 192.168.135.0/24

```

- 工作节点

```bash
pool node-manager-1 iburst
```

- 重启chronyd服务

```bash
systemctl restart chronyd.service
```

- 查看是否同步成功

```bash
chronyc sources
```

- 时间选择源成功会带一个`*`

```bash
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^? 120.197.116.202               1   7   110    50   +895us[+2554us] +/-   99ms
^* 203.107.6.88                  2   6    17    54  -2056us[ -397us] +/-   58ms
```

## 5. 集群配置文件

集群配置文件定义了集群运行的配置，如HDFS集群NameNode、DataNode的数据目录、YARN资源调度器的配置，其中核心主要有如下配置：

### 5.1. core-site.xml

`core-site.xml`定义了整个集群的全局属性，尤其是 HDFS 的入口和临时目录。

```xml
<configuration>
<!-- 文件系统入口：告知客户端和 DataNode，NameNode 运行在哪台机器及其通信端口（默认 9000 或 8020） -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://node-manager-1:9000</value>
    </property>

<!-- 临时数据根目录：Hadoop 运行时的元数据、数据块索引默认都存在这里。如果不改，默认在 /tmp，系统重启数据就全丢了。-->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/hadoop/dfs</value>
    </property>

<!-- Web端静态用户：你在浏览器访问 http://node-namager-1:9870 查看文件时，Hadoop 会默认以此身份进行操作 -->
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>hadoop</value>
    </property>

<!-- I/O 缓冲区大小：设置序列化文件时使用的缓冲区大小。131072 byte 即 128KB，能显著减少磁盘寻址次数，提升读写效率。-->
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
    </property>
</configuration>
```

### 5.2. hdfs-site.xml

这个文件决定了数据的安全性和物理存储位置。

```xml
<configuration>

<!-- 副本数量：每个数据块在集群中保存几份 -->
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>

<!-- 辅助节点地址：定义 SecondaryNameNode 在哪运行。它负责定期合并镜像文件和日志，防止 NameNode 启动过慢 -->
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>node-worker-3:9868</value>
    </property>

<!-- 权限检查检查开关：设为 false 则关闭 HDFS 内部的 Linux 式权限校验。在内部开发环境常用，防止权限不足报错 -->
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>

<!-- NameNode web ui 访问地址 -->
    <property>
        <name>dfs.namenode.http-address</name>
        <value>node-manager-1:9870</value>
    </property>

<!-- 元数据存放路径：NameNode 存储 fsimage（系统镜像）的位置。运维通常会配置多个路径（甚至是挂载的 NFS），实现元数据冗余 -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://${hadoop.tmp.dir}/namenode</value>
    </property>

<!-- 数据块存放路径：DataNode 存储真实物理数据块的地方。可以配置多个磁盘路径（用逗号分隔），实现多盘并行读写 -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://${hadoop.tmp.dir}/datanode</value>
    </property>

</configuration>
```

### 5.3. yarn-site.xml

这里是配置yarn资源调度管理的配置。

```xml<
<configuration>

<!-- 资源调度中心地址：指定 ResourceManager 运行的主机，它是 YARN 集群的“大脑” -->
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>node-manager-1</value>
    </property>

<!-- 辅助服务：告知 NodeManager 启动 Shuffle 服务，这是运行 MapReduce 计算任务的必要前提 -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>

<!-- 单个任务最大内存：防止某个不规范的任务直接把单台机器的内存吃光。-->
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>4096</value>
    </property>

<!-- 它决定了哪些系统环境变量可以从 NodeManager 传递给正在运行的 Container（容器） -->
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>

</configuration>
```

### 5.4. mapred-site.xml

该文件主要用于配置 MapReduce 作业的运行参数

```xml
<configuration>

<!-- 必填项。指定MapReduce计算框架。如果保持默认值，MapReduce 将只在本地进程运行，不提交到集群。-->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

<!-- 历史服务器的 RPC 地址，用于获取作业状态。-->
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>node-worker-1:10020</value>
    </property>

<!-- 历史服务器的 Web 界面地址，运维人员在浏览器查看日志的入口 -->
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>node-worker-1:19888</value>
    </property>

</configuration>
```

### 5.5. workers

简单来说，它告诉 Hadoop 的主节点（Master）：“哪些机器是干活的从节点？”

```bash
node-worker-1
node-worker-2
node-worker-3
```

### 5.6. 分发配置

在`node-manager-1`主机修改完集群配置文件之后，需要进行分发到其它主机，本文集群规模只有3个工作节点，作为分布式集群的可扩展性，机器的数量可以横向扩展非常多台，为了日后方便管理，最好的办法通过自己写脚本来批量同步。

示例脚本：

```bash
#!/bin/bash
set -e
host_list=("node-worker-1" "node-worker-2" "node-worker-3")

function hadoop {
    dir_path="/hadoop/src/hadoop-3.3.6"
    for host in ${host_list[@]}
    do
        scp -r ${dir_path} hadoop@${host}:${dir_path}
    done
}

function env {
    file_path="/home/hadoop/.bashrc"
    for host in ${host_list[@]}
    do
        scp ${file_path} hadoop@${host}:${file_path}
    done
}

function usage {
    echo "This script is a file transfer assistant."
    echo "usage: $0 func"
    echo "func:"
    echo -e "\thadoop: Transfer the entire Hadoop directory to the target host"
    echo -e "\tenv：Transfer the entire user env file to the target host"
    echo "Example:"
    echo -e "\t$0 hadoop"
}

case $1 in
    hadoop)
        hadoop
        ;;
    env)
        env
        ;;
    *)
        usage
        ;;
esac

```

## 6. 启动Hadoop集群

启动一个 Hadoop 集群是一个严谨的过程，顺序至关重要。如果顺序错误，可能会导致 NameNode 进入安全模式或 DataNode 无法正常连接。

以下是启动 Hadoop 3.x 标准集群（HDFS + YARN）的正确步骤：

### 6.1. 首次启动

如果是第一次启动集群，必须格式化 NameNode。

> [!CAUTION]
> 
> 不要在已运行并存放数据的集群上执行此操作，这会删除所有元数据。

```bash
hdfs namenode -format
```

### 6.2. 启动HDFS

如果之前己经格式化过`namenode`可以直接跳过**首次启动**直接启动`hdfs`集群。

```bash
start-dfs.sh
```

> [!TIP]
> 
> 这个操作是对整个集群的hdfs启动。

### 6.3. 启动 YARN 资源管理

```bash
start-yarn.sh
```

### 6.4. 方式二(单点启动)

集群内的节点也可以单点启动，这在维护集群的时候非常有用，对故障的单台节点主机操作。

- namenode

```bash
hdfs --daemon start namenode
```

- datanode

```bash
hdfs --daemon start datanode
```

- resourcemanager

```bash
yarn --daemon start resourcemanager
```

- nodemanager

```bash
yarn --daemon start nodemanager
```

> [!TIP]
> 
> 同样停止相关组件的服务可以用`stop`如：`yarn --daemon stop nodemanager`

## 7. 验证集群

启动完成后，不要直接开始跑任务，先检查组件是否齐全。

### 7.1. 检查进程

在各节点输入 jps，你应该能看到以下进程：

- 主节点：NameNode, SecondaryNameNode, ResourceManager

- 从节点：DataNode, NodeManager

> [!NOTE]
> 
> `SecondaryNameNode`进程取决于配置文件将它放在哪个节点上运行。

### 7.2. Web UI 界面检查

打开浏览器访问以下地址（将 master-ip 替换为你的服务器 IP）:

- HDFS 状态：http://master-ip:9870 (Hadoop 3.x) 或 http://master-ip:50070 (Hadoop 2.x)

- YARN 状态：http://master-ip:8088

- JobHistoryServer状态：http://node-worker-1:19888

> [!NOTE]
> 
> JobHistoryServer如果没有自动启动，则需要通过命令：`mapred --daemon start historyserver`来启动该服务。
