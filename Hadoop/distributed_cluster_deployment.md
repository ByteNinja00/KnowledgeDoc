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

## 4.2. 安装JDK

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


