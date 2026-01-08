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