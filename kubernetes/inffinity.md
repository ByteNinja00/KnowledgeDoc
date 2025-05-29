# 调度亲和性

是 Kubernetes 中用于 Pod 调度亲和性（Affinity）与反亲和性（Anti-Affinity）策略 的配置字段，它用于控制 Pod 被调度到哪些 Node 或与哪些 Pod 进行共存或隔离。

这类规则用于实现更细粒度的调度控制，是在 nodeSelector 和 nodeName 的基础上更高级、功能更丰富的机制。

三种调度规则：

- nodeAffinity
- podAffinity
- podAntiAffinity

两种类型：

- **requiredDuringSchedulingIgnoredDuringExecution**：必须匹配，不匹配就调度失败。
- **preferredDuringSchedulingIgnoredDuringExecution**：尽量匹配，匹配则优先调度。

## 1. nodeAffinity

Pod 应该调度到哪些 Node 上 (节点亲和性)。

