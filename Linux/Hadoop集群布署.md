# Hadoop分布式集群布署

Hadoop 是一个**开源的分布式计算框架**，用于在多台服务器组成的集群上存储和处理海量数据。  
它最核心的能力是：**把大数据分成小块，分给很多机器同时处理**。

## Hadoop核心组件

Hadoop 有三个主要模块：

1. **HDFS（Hadoop Distributed File System）—— 分布式存储系统**
   
   把大文件拆分成多个小块，存放在不同节点。
   
   - 高吞吐量
   
   - 多副本机制（默认 3 副本）
   
   - 容错性强（节点挂掉数据不丢）
   
   组成；
   
   - **NameNode**：管理元数据（文件在哪个节点）
   
   - **DataNode**：真实存储数据

2. **YARN —— 分布式资源管理系统**
   
   管理 CPU、内存 等资源 + 调度任务
   
   组成；
   
   - **ResourceManager (RM)**：全局资源调度
   
   - **NodeManager (NM)**：每台服务器的资源管理

3. **MapReduce —— 分布式计算框架**
   
   把任务拆成小任务并行执行。
   
   模型包括：
   
   - **Map**：数据拆分处理
   
   - **Reduce**：结果汇总处理

## 规划资源

| 主机节点名               | 节点IPv4         | 操作系统     | 集群角色                                          |
| ------------------- | -------------- | -------- | --------------------------------------------- |
| node.master.hadoop  | 192.168.182.10 | Rocky9.6 | NameNode、ResourceManager、DataNode、NodeManager |
| node01.slave.hadoop | 192.168.182.11 | Rocky9.6 | DataNode、NodeManager、SecondaryNameNode        |
| node02.slave.hadoop | 192.168.182.12 | Rocky9.6 | DataNode、NodeManager                          |

## 1. 初始化布署环境

- **设置主机名**

```bash
hostnamectl set-hostname node.master.hadoop
hostnamectl set-hostname node01.slave.hadoop
hostnamectl set-hostname node02.slave.hadoop
```

- **配置主机名-IP的映射**

```bash
192.168.182.10 node.master.hadoop
192.168.182.11 node01.slave.hadoop
192.168.182.12 node02.slave.hadoop
```

- **设置免密登陆(所有节点)**

```bash
ssh-copy-id  root@node.master.hadoop
ssh-copy-id  root@node01.slave.hadoop
ssh-copy-id  root@node02.slave.hadoop
```

- **设置时间同步**

主服务(*chronyd.service*)的时钟源指向公共时钟源；

```bash
pool ntp.aliyun.com iburst maxsources 2
allow 192.168.182.0/24
```

**从服务的时钟源指向主服务；**

```bash
pool node.master.hadoop iburst
```

- **关闭防火墙；**

```bash
systemctl disable firewalld.service --now
```

- **关闭SELinux，重启系统生效；**

```bash
# /etc/selinux/config 
SELINUX=disabled
```

- **关闭系统交换分区(SWAP)**

```bash
swapoff -a
# 永久关闭，在/etc/fstab 以#号注释掉
```

## 2. 安装必要软件包

hadoop运行时需要特定的软件依赖。

### 2.1. 安装JAVA

运行hadoop需要java运行时环境，导航至[ORACLE官网]([Java Downloads | Oracle ASEAN](https://www.oracle.com/asean/java/technologies/downloads/#java8))下载JDK。

- 解压JDK安装压缩包

```bash
tar -zxvf jdk-8u471-linux-x64.tar.gz -C /opt/
```

> 所有节点都需要安装。

## 3. 安装Hadoop

Hadoop 以源代码压缩包的形式发布，为了方便起见，还提供了相应的二进制压缩包。

这些下载文件通过[镜像站点]([Apache Hadoop](https://hadoop.apache.org/releases.html))分发。

- 解压Hadoop二进制安装包

```bash
tar -zxvf hadoop-3.3.6.tar.gz -C /opt/
```

> 所有节点都需要安装。

## 4. 配置Hadoop集群

Hadoop集群的核心配置文件主要位于 `HADOOP_HOME/etc/hadoop/` 目录下，这些配置文件用来配置Hadoop集群的各个组件，比如HDFS、YARN等。

1. **core-site.xml**
   
   这个文件用于配置Hadoop核心服务的相关信息，主要是HDFS和YARN所需的基本配置信息。

2. **hdfs-site.xml**
   
   这个文件配置与HDFS（Hadoop分布式文件系统）相关的属性，主要包括HDFS的存储路径、HDFS副本数等参数。HDFS是Hadoop的核心组件之一，负责存储集群中的大规模数据。

3. **yarn-site.xml**
   
   这个文件用于配置YARN（Yet Another Resource Negotiator）相关的属性。YARN是Hadoop集群的资源管理层，负责管理集群中的计算资源并调度作业。

4. **mapred-site.xml**
   
   这个文件是针对MapReduce框架的配置文件。它主要配置MapReduce作业的行为，通常在YARN集群上运行MapReduce作业时使用。

5. `masters` 和 `slaves`
   
   - **masters**：指定集群中的主节点，通常是NameNode和ResourceManager所在的节点。
   
   - **slaves**：指定集群中的从节点，通常是DataNode和NodeManager所在的节点。

6. **hadoop-env.sh**
   
   这个脚本文件用来配置Hadoop环境变量。你可以在这里设置Java的安装路径、Hadoop的内存参数等。

7. **log4j.properties**
   
   Hadoop使用log4j作为日志框架，这个文件用于配置Hadoop的日志输出级别和格式。

8. `hadoop-daemon.sh` 和 `start-dfs.sh` 等
   
   这些是用于启动和停止Hadoop集群的脚本文件，通常无需手动修改，但它们控制着Hadoop的各个组件的启动顺序和方式。

### 4.1. 配置Hadoop集群环境变量

通过 etc/hadoop/hadoop-env.sh 和 etc/hadoop/yarn-env.sh 设置特定于站点的值，来控制发行版 bin/ 目录中的 Hadoop 脚本。

```bash
export JAVA_HOME=/opt/jdk1.8.0_471/bin
export HADOOP_HOME=/opt/hadoop-3.3.6
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export HDFS_NAMENODE_USER=root
```

> 创建软链接：`ln -s /opt/hadoop-3.3.6/etc/hadoop/hadoop-env.sh /etc/profile.d/`

### 4.2. Hadoop核心服务配置

该配置文件在：`$HADOOP_HOME/etc/hadoop/core-site.xml`, **所有节点都要配置主节点的位置。**

```xml
<configuration>
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://node.master.hadoop:9000</value> <!-- 指向主节点的位置-->
	</property>
</configuration>
```

### 4.3. 配置HDFS

该配置文件在：`$HADOOP_HOME/etc/hadoop/hdfs-site.xml`,所有节点都需要配置：

- `dfs.name.dir` 只在主机点(NameNode)上配置

- `dfs.data.dir` 在从节点(DataNode)上配置

> 如果主节点上也配置`dfs.data.dir`则表明主节点同时也会作为DataNode角色

```xml
<configuration>
	<property>
		<name>dfs.replication</name>
		<value>3</value> <!-- 副本数可以根据需要设置，通常为3 -->
	</property>
	<property>
		<name>dfs.name.dir</name>
		<value>/data/hdfs/nameNode</value>
	</property>
	<property>
		<name>dfs.data.dir</name>
		<value>/data/hdfs/dataNode</value>
	</property>

</configuration>
```

- 配置`secondary namenode`

```xml
<property>
     <name>dfs.secondary.http.address</name>
     <value>0.0.0.0:50090</value>
</property>

<!-- 设置 Secondary NameNode 的工作目录 -->
<property>
     <name>dfs.namenode.secondary.dir</name>
     <value>/data/hdfs/secondary</value> <!-- Secondary NameNode 存储 fsimage 和 edits 文件的位置 -->
</property>


```

### 4.4. 配置MapReduce

该配置文件在：`$HADOOP_HOME/etc/hadoop/mapred-site.xml`,所有节点都需要配置MapReduce的计算框架。

```xml
<configuration>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
</configuration>
```

### 4.5. 配置YARN的资源管理器信息。

该配置文件在：`$HADOOP_HOME/etc/hadoop/yarn-site.xml`,所有节点都需要配置，虽然 ResourceManager 只在主节点上运行，但你需要在集群中的每台机器上配置 YARN，以确保每个 NodeManager 知道应该联系哪个 ResourceManager。

```xml
<configuration>

	<!-- Site specific YARN configuration properties -->
	<property>
		<name>yarn.resourcemanager.hostname</name>
		<value>node.master.hadoop</value>
	</property>

</configuration>
```

### 4.6. 配置workers

该配置文件在：`$HADOOP_HOME/etc/hadoop/wokers`，只在主节点上配置。

```xml
node01.slave.hadoop
node02.slave.hadoop
```

## 5. 启动集群

在启动集群之前，必须格式化HDFS，这将初始化NameNode的元数据。

- 格式化HDFS（在主节点上）

```bash
hdfs namenode -format
```

- 启动Hadoop集群（在主节点上）

> 启动Hadoop集群时，必须先启动HDFS，再启动YARN。

```bash
start-dfs.sh  # 启动HDFS
start-yarn.sh  # 启动YARN
```
