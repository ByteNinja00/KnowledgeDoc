# Hadoop高可用分布式集群

在Hadoop集群中将单节点搭建升级到高可用（HA）模式，主要目的是提高系统的容错性，使得某个节点故障时，集群仍然能够正常工作。具体来说，在Hadoop HA模式下，通常是为了确保 **NameNode** 的高可用性。

以下是将现有的单节点Hadoop集群升级为 **HA模式** 的详细步骤：

## 1. 环境准备

步骤可以参考[Hadoop分布式集群布署](/Linux/hadoop/Hadoop分布式集群布署.md)，只不过在原有的集群基础上增加一台node-master-2节点，作为高可用节点。

整体的资源规划：

| 主机名           | IPAddress      | 角色分配 (HDFS + YARN + ZK)                      | 关键进程                                  |
| ------------- | -------------- | -------------------------------------------- | ------------------------------------- |
| node-master-1 | 192.168.182.10 | NameNode (Active), ResourceManager (Standby) | NameNode, DFSZKFC, ResourceManager    |
| node-master-2 | 192.168.182.11 | NameNode (Standby), ResourceManager (Active) | NameNode, DFSZKFC, ResourceManager    |
| node-slave-1  | 192.168.182.21 | DataNode, Zookeeper, JournalNode             | DataNode, QuorumPeerMain, JournalNode |
| node-slave-2  | 192.168.182.22 | DataNode, Zookeeper, JournalNode             | DataNode, QuorumPeerMain, JournalNode |
| node-slave-3  | 192.168.182.23 | DataNode, Zookeeper, JournalNode             | DataNode, QuorumPeerMain, JournalNode |

> [!IMPORTANT]
> 在 HA 模式下，**Master1 和 Master2 必须能够免密登录所有节点**（包括对方），因为 ZKFC 在执行切换时需要通过 SSH 发送指令关闭进程（Fencing 隔离机制）。

## 2. Zookeeper 集群部署

在 Hadoop HA 中，Zookeeper 负责监控 NameNode 的健康状况，并在 Active 节点宕机时，确保只有一台机器能抢占到排他锁，从而晋升为新的 Active。

### 2.1. 安装zookeeper

根据之前的规划，将 Zookeeper 安装在三台 Slave 机器上：**node-slave-1、node-slave-2、node-slave-3**。

```bash
tar zxvf ~/apache-zookeeper-3.8.5-bin.tar.gz -c /hadoop/ha
```

- 拷贝配置模板

```bash
cp /hadoop/ha/zookeeper/conf/zoo_sample.cfg /hadoop/ha/zookeeper/conf/zoo.cfg
```

- 修改配置文件内容

```toml
#用于心跳机制。比如，最小的会话超时时间默认是 2 x ticktime
tickTime=2000
# Leader 服务器等待 Follower 服务器连接并完成数据同步的最大 tick 时间数。
# 10 x times 2000ms = 20 秒。如果 Follower 在 20 秒内没连上 Leader，则同步失败。
initLimit=10
# Leader 与 Follower 之间发送消息、请求和应答时间的长度（tick 时间数）。
# 5 x 2000ms=10s 如果 Follower 在 10 秒内没有给 Leader 反馈，该 Follower 将被丢弃。
syncLimit=5
# 数据存放目录（记得创建这个目录）
dataDir=/hadoop/ha/zookeeper/zkData
# 客户端连接 ZooKeeper 服务器的端口。
clientPort=2181
# 集群节点配置 (server.A=B:C:D)
# A是一个数字，代表服务器ID
# B是服务器地址
# C是集群内通信端口
# D是选举端口
server.1=node-slave-1:2888:3888
server.2=node-slave-2:2888:3888
server.3=node-slave-3:2888:3888
```

- 创建 myid 文件 (至关重要)
  
  - 在 **Slave1** 的 `dataDir` 目录下创建 `myid`，内容写入 `1`。
  
  - 在 **Slave2** 的 `dataDir` 目录下创建 `myid`，内容写入 `2`。
  
  - 在 **Slave3** 的 `dataDir` 目录下创建 `myid`，内容写入 `3`。

Zookeeper 通过 `myid` 文件来确定当前节点是 `zoo.cfg` 中的哪一个 `server`。

- 分发并启动

将配置好的 Zookeeper 文件夹同步到 Slave2 和 Slave3。然后在三台 Slave 上分别执行：

```bash
bin/zkServer.sh start
```

- 验证状态

在三台机器上分别运行：

```bash
bin/zkServer.sh status
```

> [!NOTE]
> 
> **预期结果**：你会看到一个 `Mode: leader` 和两个 `Mode: follower`。

### 2.2. ZK集群管理脚本

自己编写一个远程管理脚本，前提是需要在配置了免密登陆的机器上执行：

```bash
#!/bin/bash
ZK_HOST=("node-slave-1" "node-slave-2" "node-slave-3")

function usage {
	echo -e "\033[1;38mUsage:\033[0m $0 command"
	echo -e "\t\033[1;38mCommand:\033[0m [start-zk, stop-zki, status]"
	echo -e "\t\033[1;38mExample:\033[0m $0 start-zk"
}

function start-zk {
for host in ${ZK_HOST[@]}
do
	ssh -n -o  StrictHostKeyChecking=no hadoop@${host} "/home/hadoop/zookeeper/bin/zkServer.sh start"
	echo -e "\033[0;33m- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\033[0m"
done
}

function stop-zk {
for host in ${ZK_HOST[@]}
do
	ssh -n -o StrictHostKeyChecking=no hadoop@${host} "/home/hadoop/zookeeper/bin/zkServer.sh stop"
	echo -e "\033[0;31m- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\033[0m"
done
}

function stat-zk {
for host in ${ZK_HOST[@]}
do
        ssh -n -o StrictHostKeyChecking=no hadoop@${host} "/home/hadoop/zookeeper/bin/zkServer.sh status"
	echo -e "\033[0;32m- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\033[0m"
done

}

case $1 in
	start)
		start-zk
		;;
	stop)
		stop-zk
		;;
	status)
		stat-zk
		;;
	*)
		usage
		;;
esac

```

> [!NOTE]
> 
> 替换HOST变量内的数组元素，也就是需要管理的zk主机名。



## 3. Hadoop HA 核心配置文件修改

现在 Zookeeper 跑起来了，回到 **Master1**，修改 Hadoop 的核心配置文件。这是 HA 搭建中最复杂的一步，要仔细核对。

### 3.1. `hdfs-site.xml` (核心配置)

这个文件定义了逻辑服务名、JournalNode 地址以及隔离机制。

```xml
<configuration>
    <property>
        <name>dfs.nameservices</name>
        <value>mycluster</value>
    </property>

    <property>
        <name>dfs.ha.namenodes.mycluster</name>
        <value>nn1,nn2</value>
    </property>

    <property>
        <name>dfs.namenode.rpc-address.mycluster.nn1</name>
        <value>master1:8020</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.mycluster.nn1</name>
        <value>master1:9870</value>
    </property>

    <property>
        <name>dfs.namenode.rpc-address.mycluster.nn2</name>
        <value>master2:8020</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.mycluster.nn2</name>
        <value>master2:9870</value>
    </property>

    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://slave1:8485;slave2:8485;slave3:8485/mycluster</value>
    </property>

    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>

    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>sshfence</value>
    </property>
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/root/.ssh/id_rsa</value>
    </property>
</configuration>
```

### 3.2. core-site.xml

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://mycluster</value>
    </property>

    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/module/hadoop-3.1.3/data</value>
    </property>

    <property>
        <name>ha.zookeeper.quorum</name>
        <value>slave1:2181,slave2:2181,slave3:2181</value>
    </property>
</configuration>
```
