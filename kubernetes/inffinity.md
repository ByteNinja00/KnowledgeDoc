# 调度亲和性

是 Kubernetes 中用于 Pod 调度亲和性（Affinity）与反亲和性（Anti-Affinity）策略 的配置字段，它用于控制 Pod 被调度到哪些 Node 或与哪些 Pod 进行共存或隔离。

这类规则用于实现更细粒度的调度控制，是在 nodeSelector 和 nodeName 的基础上更高级、功能更丰富的机制。

**三种调度规则：**

- nodeAffinity
- podAffinity
- podAntiAffinity

**两种类型：**

- **requiredDuringSchedulingIgnoredDuringExecution**：必须匹配，不匹配就调度失败。
- **preferredDuringSchedulingIgnoredDuringExecution**：尽量匹配，匹配则优先调度。

## 1. nodeAffinity

Pod 应该调度到哪些 Node 上 (节点亲和性)。

### 字段结构

可以用`kubectl explain pod.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution`查看说明，每一层都是对象引用。

#### 软亲和性

**preferredDuringSchedulingIgnoredDuringExecution <\[]PreferredSchedulingTerm>**

|字段|类型|描述|
|---|----|----|
|preference|NodeSelectorTerm|匹配规则，用于选择更希望调度到的节点|
|weight|integer|匹配该规则的优先级，数值越大越优先调度到匹配的节点。可以有多个规则|

##### preference规则语法

preference 是一个 NodeSelectorTerm，由多个 matchExpressions 或 matchFields 组成。

|字段|类型|
|---|----|
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

示例-要求节点有 disktype=ssd 并且位于 zone=cn-beijing-a 的节点：

```yaml
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 100
  preference:
    matchExpressions:
    - key: disktype
      operator: In
      values:
      - ssd
    - key: topology.kubernetes.io/zone
      operator: In
      values:
      - cn-beijing-a
```

> [!TIP]
> 意思是：调度器偏好将此 Pod 安排到标签为 disktype=ssd 且 zone=cn-beijing-a 的节点上，如果没有这样的节点，仍然可以调度到其他节点。

- **matchFields**

matchFields 这个字段在这个位置——preferredDuringSchedulingIgnoredDuringExecution.preference（即 soft node affinity 中）——是非法的，不能用！

在实践中，只有 requiredDuringSchedulingIgnoredDuringExecution 支持使用 matchFields，在 preferredDuringSchedulingIgnoredDuringExecution 里使用会：

被忽略；

甚至导致调度失败（depending on version and admission controller）。

#### 硬亲和性

**requiredDuringSchedulingIgnoredDuringExecution \<NodeSelector>**

|字段|类型|
|----|----|
|nodeSelectorTerms|[]NodeSelectorTerm|

##### nodeSelectorTerms语法规则

|字段|类型|
|---|----|
|matchExpressions|[]NodeSelectorRequirement|
|matchFields|[]NodeSelectorRequirement|

- **matchFields**

matchFields 是用于匹配 节点对象的字段（而不是标签），用于指定 Pod 必须调度到满足特定字段值的节点。

**常见的key值：**

| key                      | 描述                             |
| ------------------------ | ------------------------------ |
| `metadata.name`          | 匹配节点的名称                        |
| `metadata.labels['xxx']` | ❌ 不支持，标签应该用 `matchExpressions` |

> [!IMPORTANT]
> 重点：目前（截至 Kubernetes 1.30），matchFields 主要、实用的字段是：metadata.name —— 也就是说你可以通过它精确限制只能调度到哪些节点。

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchFields:
          - key: metadata.name
            operator: In
            values:
              - node-1
```

> [!TIP]
> 这个例子的含义是：Pod 只能调度到名为 node-1 的节点上。

## podAffinity

