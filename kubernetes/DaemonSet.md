# DeamonSet

DaemonSet 是 Kubernetes 中的一种控制器资源，用于确保集群中每个（或特定）节点上运行一个 Pod 的副本。这在以下场景中非常常见：

- 节点级日志收集器（如 Fluentd、Filebeat）
- 节点级监控工具（如 Prometheus Node Exporter）
- 网络组件（如 CNI 插件）

**核心特点**

| 特性                     | 说明                                               |
| ---------------------- | ------------------------------------------------ |
| 每个节点运行一个 Pod           | 默认在所有节点上部署一个副本（除非指定 `nodeSelector`、`affinity` 等） |
| 自动管理                   | 新节点加入时会自动部署；节点被移除时相应 Pod 被清除                     |
| 可与 Taint/Toleration 配合 | 支持调度到打了污点的节点，比如 master 节点                        |
| 支持更新策略                 | 可以配置 `RollingUpdate` 或 `OnDelete`                |

