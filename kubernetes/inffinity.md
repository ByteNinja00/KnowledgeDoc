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

- **preferredDuringSchedulingIgnoredDuringExecution <[]PreferredSchedulingTerm>**

|字段|类型|描述|
|---|----|----|
|preference|NodeSelectorTerm|匹配规则，用于选择更希望调度到的节点|
|weight|integer|匹配该规则的优先级，数值越大越优先调度到匹配的节点。可以有多个规则|

#### preference规则语法

preference 是一个 NodeSelectorTerm，由多个 matchExpressions 或 matchFields 组成。

|字段|类型|
|---|----|----|
|matchExpressions|[]NodeSelectorRequirement|
|matchFields|[]NodeSelectorRequirement|

- **matchExpressions:**

matchExpressions 是 NodeSelectorTerm（即 preference）中的一个字段，它是一个 条件列表，用于匹配节点上的标签（Labels），用于表达调度偏好（非强制）。

这些表达式之间是 AND 关系：即所有表达式都要匹配，节点才符合该条调度偏好。

数据结构：

```yaml
matchExpressions:
- key: <string>
  operator: <string>         
  values: [<string>, ...]    
```

operator操作符：

| 操作符            | 说明                        | 是否需要 `values` |
| -------------- | ------------------------- | ------------- |
| `In`           | `key` 的值在 `values` 里      | ✅ 需要          |
| `NotIn`        | `key` 的值不在 `values` 里     | ✅ 需要          |
| `Exists`       | 节点有这个标签键                  | ❌ 不需要         |
| `DoesNotExist` | 节点没有这个标签键                 | ❌ 不需要         |
| `Gt`           | 标签值是整数字符串，且 > `values[0]` | ✅ 只用第一个值      |
| `Lt`           | 标签值是整数字符串，且 < `values[0]` | ✅ 只用第一个值      |
