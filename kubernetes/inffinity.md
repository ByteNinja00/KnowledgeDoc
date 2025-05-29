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

### 字段结构

可以用`kubectl explain pod.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution`查看说明，每一层都是对象引用。

- preferredDuringSchedulingIgnoredDuringExecution <[]PreferredSchedulingTerm>
|字段|类型|描述|
|---|----|----|
|preference|NodeSelectorTerm|匹配规则，用于选择更希望调度到的节点|
|weight|integer|匹配该规则的优先级，数值越大越优先调度到匹配的节点。可以有多个规则|