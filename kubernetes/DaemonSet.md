# DeamonSet

DaemonSet 是 Kubernetes 中的一种控制器资源，用于确保集群中每个（或特定）节点上运行一个 Pod 的副本。这在以下场景中非常常见：

- 节点级日志收集器（如 Fluentd、Filebeat）
- 节点级监控工具（如 Prometheus Node Exporter）
- 网络组件（如 CNI 插件）

## 核心特点

| 特性                     | 说明                                               |
| ---------------------- | ------------------------------------------------ |
| 每个节点运行一个 Pod           | 默认在所有节点上部署一个副本（除非指定 `nodeSelector`、`affinity` 等） |
| 自动管理                   | 新节点加入时会自动部署；节点被移除时相应 Pod 被清除                     |
| 可与 Taint/Toleration 配合 | 支持调度到打了污点的节点，比如 master 节点                        |
| 支持更新策略                 | 可以配置 `RollingUpdate` 或 `OnDelete`                |

## Metadata

**[参考Metadata字段](/kubernetes/PodFeilds.md#metadata)**

## Spec

定义DaemonSet控制器的期望与行为。

|字段|类型|描述|
|----|---|---|
|minReadySeconds|\<integer>|控制 Pod 在就绪状态（Ready）后至少保持多长时间才被认为可用（available） 的字段，主要用于滚动更新过程中判断新 Pod 是否可用的一个延迟机制。|
|revisionHistoryLimit|\<integer>|保留的历史版本（旧 ReplicaSet）的数量。|
|selector|\<LabelSelector>|(必需要的)是 DaemonSet 中用于匹配 Pod 的标签选择器（Label Selector），它是一个 必须设置 的字段。|
|template|\<PodTemplateSpec>|(必需要的)|
|updateStrategy|\<DaemonSetUpdateStrategy>|ll|

### Selector

明确告诉 DaemonSet：它应该管理哪些 Pod。

表达式参考[Deployment Selector](/kubernetes/Deployment.md#selector)

### template

- **metadata**: [参考Metadata字段](/kubernetes/PodFeilds.md#metadata)

- **spec**: [参考spec](/kubernetes/Deployment.md#spec)