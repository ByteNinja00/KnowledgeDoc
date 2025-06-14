# 调度亲和性

调度亲和性是指：用来在调度阶段表达「把 Pod 放到哪里（或不放到哪里）」的策略。它包含三大块：

1. **Node Affinity（节点亲和性）**
2. **Pod Affinity（Pod 亲和性）**
3. **Pod Anti‑Affinity（Pod 反亲和性）**

## 一、Node Affinity（节点亲和性）

根据匹配节点条件来选择调度亲和性，分为软亲和性和硬亲和性。

### 软亲和性（nodeAffinity）

`preferredDuringSchedulingIgnoredDuringExecution` 是 Kubernetes nodeAffinity 里的一个软性调度偏好（Soft Affinity），意思是「调度器尽量把 Pod 调度到符合这些偏好的节点上，但如果没有满足条件的节点，也不会阻止调度」，是调度时的倾向性选项，不是硬性约束。

**字段结构：**

- preferredDuringSchedulingIgnoredDuringExecution `<[]PreferredSchedulingTerm>`
  - preference    `<NodeSelectorTerm> -required-`
    - matchExpressions      `<[]NodeSelectorRequirement>`:根据节点标签的匹配表达式。
      - key `<string> -required-`: 匹配键。
      - operator `<string> -required-`: 操作符，枚举值：
        - `"DoesNotExist"`
        - `"Exists"`
        - `"Gt"`
        - `"In"`
        - `"Lt"`
        - `"NotIn"`
      - values `<[]string>`: 匹配值。
  - weight `<integer> -required-`
    - matchFields   `<[]NodeSelectorRequirement>`：根据节点的字段来匹配。
      - key   `<string> -required-`
      - operator      `<string> -required-`
        - `"DoesNotExist"`
        - `"Exists"`
        - `"Gt"`
        - `"In"`
        - `"Lt"`
        - `"NotIn"`
      - values        `<[]string>`
  - weight `<integer> -required-`: 权重值设置(1-100)之间。

> [!TIP]
> 逻辑关系：
>
>- `<[]PreferredSchedulingTerm>` 之间是`OR`和加权关系。
>
>- `<[]NodeSelectorRequirement>` 内部是`AND`关系。
>
>- 多个`values`之间是`OR`关系。

#### 示例（软亲和性）

- 根据节点的Labes来匹配调度。

```yaml
affintity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 98
        preference:
          matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values: [kube-node-1]
```

- 根据节点的Fields来匹配调度。

```yaml
affintity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 99
        preference:
          matchFields:
          - key: metadata.name
            operator: In
            values:
            - node1
```

### 硬亲和性（nodeAffinity）

`requiredDuringSchedulingIgnoredDuringExecution`是 Kubernetes Pod 的调度约束中的一个字段，用来指定 Pod 只能被调度到符合特定节点标签要求的节点上。

**字段结构：**

- requiredDuringSchedulingIgnoredDuringExecution `<NodeSelector>`
  - nodeSelectorTerms `<[]NodeSelectorTerm> -required-`
    - matchExpressions `<[]NodeSelectorRequirement>`
      - key   `<string> -required-`
      - operator `<string> -required-`
        - `"DoesNotExist"`
        - `"Exists"`
        - `"Gt"`
        - `"In"`
        - `"Lt"`
        - `"NotIn"`
      - values  `<[]string>`
    - matchFields `<[]NodeSelectorRequirement>`
      - key   `<string> -required-`
      - operator `<string> -required-`
        - `"DoesNotExist"`
        - `"Exists"`
        - `"Gt"`
        - `"In"`
        - `"Lt"`
        - `"NotIn"`
      - values  `<[]string>`

> [!TIP]
>
> - `<[]NodeSelectorTerm>` 之间为 `OR`关系。
> - `<[]NodeSelectorRequirement>` 之间为 `AND`关系。
> - `values` 之间为 `OR`关系。

#### 示例（硬亲和性）

- 根据节点的Lables来匹配调度，属于硬性要求匹配失败即调度失败，与软亲和性不同之处在于软亲和性是尽量调度，如果匹配失败也不影响其调度到其它节点。

```yaml
affinity:
    nodeAffinity:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
```

- 根据节点的字段来调度:

```yaml
affinity:
    nodeAffinity:
      nodeSelectorTerms:
      - matchFields:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1
          - node2
```

## 二、Pod Affinity（Pod 亲和性）

Pod 亲和性调度策略，用于控制某个 Pod 倾向或强制调度到与其它特定 Pod 在同一拓扑域（例如同一节点、同一区域等）上的节点。

### 软亲和性（podAffinity）

软性调度偏好。

**字段结构：**

- preferredDuringSchedulingIgnoredDuringExecution `<[]WeightedPodAffinityTerm>`
  - podAffinityTerm `<PodAffinityTerm> -required-`
    - labelSelector `<LabelSelector>`
      - matchExpressions `<[]LabelSelectorRequirement>`
        - key   `<string> -required-`
        - operator      `<string> -required-`
          - `In`
          - `NotIn`
          - `Exists`
          - `DoesNotExist`
        - values `<[]string>`
      - matchLabels `<map[string]string>`
        - `key`: `value`
    - matchLabelKeys <[]string>：这只是一个测试字段。
    - mismatchLabelKeys `<[]string>`：这是一个测试字段，需要启用 MatchLabelKeysInPodAffinity 特性门控（默认启用）。
    - namespaceSelector `<LabelSelector>`: 默认情况下，podAffinityTerm 的 labelSelector 只会在 本命名空间 里寻找匹配的 Pod。要想在 其它命名空间 的 Pod 上也匹配。
      - matchExpressions `<[]LabelSelectorRequirement>`
        - key   `<string> -required-`
        - operator      `<string> -required-`
          - `In`
          - `NotIn`
          - `Exists`
          - `DoesNotExist`
        - values `<[]string>`
      - matchLabels `<map[string]string>`
        - `key`: `value`
    - namespaces `<[]string>`: 显式指定一个命名空间列表，表示：在这些命名空间内搜索 labelSelector 匹配的 Pod。
    - topologyKey `<string> -required-`: topologyKey 就是「以什么维度判断节点属于同一个拓扑域」的依据。匹配节点键。
  - weight `<integer> -required-`

> [!TIP]
> 逻辑关系:
>
> - `<[]WeightedPodAffinityTerm>` 之间为加权和`OR`的逻辑关系。
> - `<[]LabelSelectorRequirement>` 内部之间为`AND`关系。
> - `<[]LabelSelectorRequirement>` 中 `values`之间为`OR`关系

### 硬亲和性（podAffinity）

调度时的硬性要求。

**字段结构：**

- requiredDuringSchedulingIgnoredDuringExecution `<[]PodAffinityTerm>`
  - labelSelector `<LabelSelector>`
  - matchLabelKeys `<[]string>`
  - mismatchLabelKeys `<[]string>`
  - namespaceSelector `<LabelSelector>`
  - namespaces `<[]string>`
  - topologyKey `<string> -required-`

## 三、Pod Anti‑Affinity（Pod 反亲和性）
