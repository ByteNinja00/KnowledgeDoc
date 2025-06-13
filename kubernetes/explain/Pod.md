# Pod资源

Pod 是 Kubernetes 中可以部署的最小单位。

它包含了一个或多个容器，这些容器共享同一个网络和存储环境，彼此紧密绑定，就像“在一台机器上的进程群”。

## 网络

- Pod 内部的容器可以通过 localhost 直接通信。

- Pod 有自己的 IP 地址（由 CNI 插件提供）。

- Pod 之间不能通过 localhost 通信，要用服务（Service）进行连接。

## 生命周期

Pod 的生命周期是短暂的，不可变的。如果 Pod 被删除或崩溃：

- 它会被新的 Pod 替代（但不是“原地复活”，是一个新的 Pod）

- Pod 的 IP 地址会变

所以如果需要“长期存在”的服务，要配合 Deployment 或 StatefulSet 来管理 Pod。

## 字段结构

|字段|类型|描述|
|---|----|----|
|`apiVersion`|`<string>`|值：`v1`|
|`kind`|`<string>`|值：`Pod`|
|`metadata`|`<ObjectMeta>`|元数据部分，用于标识和管理对象。|
|`spec`|`<PodSpec>`|Pod 的核心部分，定义运行什么、怎么运行。|
|`status`|`<PodStatus>`|Pod最近运行状态，可能不是最新的数据。由系统填充/只读。|

