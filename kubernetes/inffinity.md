# 亲和性

是 Kubernetes 中用于 Pod 调度亲和性（Affinity）与反亲和性（Anti-Affinity）策略 的配置字段，它用于控制 Pod 被调度到哪些 Node 或与哪些 Pod 进行共存或隔离。

## nodeAffinity

基于`node`亲和性调度。

### 软亲和性

软亲和性基于偏好来进行调度，尽量匹配，匹配则优先调度。

**FIELD: preferredDuringSchedulingIgnoredDuringExecution <[]PreferredSchedulingTerm>**

#### 字段结构

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: <int>
        preference:
          matchExpressions:
            - key: <string>
              operator: <In|NotIn|Exists|DoesNotExist|Gt|Lt>
              values: [<string>]
```

- **权重(weight)**

用来表示该偏好规则的“权重”，数值越大，调度器越倾向于选择符合该规则的节点。

类型：int（范围 1~100）

- **偏好(preference)**

preference 是一个 NodeSelectorTerm 对象。它用来定义一组节点选择条件，描述调度器偏好的节点。

|字段|类型|描述|
|----|----|----|
|matchExpressions|[]NodeSelectorRequirement|匹配规则表达式|
|matchFields|[]NodeSelectorRequirement|忽略，在硬亲和性才会生效。|

**matchExpressions表达式Operator运算符解析：**

| Operator       | 含义               |
| -------------- | ---------------- |
| `In`           | 节点标签的值在指定列表中     |
| `NotIn`        | 节点标签的值不在指定列表中    |
| `Exists`       | 节点有该标签（值任意）      |
| `DoesNotExist` | 节点没有该标签          |
| `Gt` / `Lt`    | 节点标签值为数字并满足大于/小于 |

### 硬亲和性

硬亲和性基于硬性原则调度，必须满足硬亲和性条件，否则调度失败，Pod将被挂起(`peding`)。

**FIELD: requiredDuringSchedulingIgnoredDuringExecution \<NodeSelector>**

#### 字段结构

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: <string>
                operator: <In | NotIn | Exists | DoesNotExist | Gt | Lt>
                values: [<string>]  # 某些 operator 不需要
```

- **nodeSelectorTerms**

它定义了调度 Pod 到节点时必须满足的标签匹配条件。

|字段|类型|描述|
|----|----|----|
|matchExpressions|[]NodeSelectorRequirement|匹配规则表达式|
|matchFields|[]NodeSelectorRequirement|匹配字段，如: `metada.name`|

**matchExpressions表达式Operator运算符解析：**

| Operator       | 含义               |
| -------------- | ---------------- |
| `In`           | 节点标签的值在指定列表中     |
| `NotIn`        | 节点标签的值不在指定列表中    |
| `Exists`       | 节点有该标签（值任意）      |
| `DoesNotExist` | 节点没有该标签          |
| `Gt` / `Lt`    | 节点标签值为数字并满足大于/小于 |

**matchFields**

matchFields 是 NodeSelectorTerm 中的一个可选字段，用于匹配节点的字段（field）值，而非标签（label）。它和 matchExpressions 类似，但匹配的是字段而不是标签。

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
                  - node-a
```

> [!NOTE]
> 以上示例Pod只会被调度到特定的节点，节点名为`node-a`

## podAffinity

用于定义一个 Pod 希望调度到与其他特定 Pod“靠近”的节点上（例如同一个节点、同一个可用区等）。这是 Kubernetes 中的“软约束”调度方式之一。

### 软亲和性

FIELD: preferredDuringSchedulingIgnoredDuringExecution <[]WeightedPodAffinityTerm>

#### 字段结构

```yaml
affinity:
  podAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: <int>
        podAffinityTerm:
          labelSelector:
            matchLabels:
            <key>: <value>
          topologyKey: "kubernetes.io/hostname"
```

- **权重(weight)**

用来表示该偏好规则的“权重”，数值越大，调度器越倾向于选择符合该规则的节点。

类型：int（范围 1~100）

- **podAffinityTerm**

用于定义软亲和性规则的核心匹配条件。

|字段|类型|描述|
|----|----|----|
|`labelSelector`|`LabelSelector`|Pod标签选择器|
|`matchLabelKeys`|[]string|匹配Pod键，不考虑值|
|`mismatchLabelKeys`|[]string|测试阶段|
|`namespaceSelector`|`LabelSelector`|用于匹配命名空间（namespace）对象的标签，然后用这些命名空间中符合条件的 Pod 来做匹配。|
|`namespace`|[]string|匹配 Pod 的命名空间，默认是当前命名空间|
|`topologyKey`|`string`|匹配的“拓扑维度”：常用为节点（kubernetes.io/hostname）或可用区|



### 硬亲和性

**FIELD: requiredDuringSchedulingIgnoredDuringExecution <[]PodAffinityTerm>**

[参考软亲和性](/kubernetes/inffinity.md#软亲和性-1)

## podAntiAffinity

用于避免将特定的 Pod 安排在某些节点或拓扑结构（如同一个节点、同一个可用区等）上，以减少资源竞争或实现高可用性。

[参考podAffinity](/kubernetes/inffinity.md#podaffinity)

## 示例

结合上述理论，分别为 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 创建场景使用案例。

### 节点亲和性

规则关系：一个匹配规则下多个条目为**且**关系，多个匹配规则条目为**或**关系。

- **软亲和性**

```yaml
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 90
          preference:
            matchExpressions:
              - key: disktype
                operator: In
                values: 
                  - ssd
        - weight: 80
          preference:
            matchExpressions:
              - key: zone
                operator: In
                values: 
                  - Shanghai
```

> [!NOTE]
> 表示该Pod偏好高度到标签为 disktype: ssd 或 zone: Shanghai的节点上。

- **硬亲和性**


```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
              - key: zone
                operator: In
                values:
                  - Shanghai
          - matchExpressions:
              - key: critype
                operator: In
                values:
                  - containerd
```

> [!NOTE]
> 表示该Pod会被调度到 disktype: ssd 且 zone: Shanghai 或 critype: containerd 的节点上。

### Pod亲和性

规则关系：一个匹配规则下多个条目为**且**关系，多个匹配规则条目为**或**关系。

