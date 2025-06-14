# 调度亲和性

调度亲和性是指：用来在调度阶段表达「把 Pod 放到哪里（或不放到哪里）」的策略。它包含三大块：

1. **Node Affinity（节点亲和性）**
2. **Pod Affinity（Pod 亲和性）**
3. **Pod Anti‑Affinity（Pod 反亲和性）**

## 一、Node Affinity（节点亲和性）

根据匹配节点条件来选择调度亲和性，分为软亲和性和硬亲和性。

### 软亲和性

`preferredDuringSchedulingIgnoredDuringExecution` 是 Kubernetes nodeAffinity 里的一个软性调度偏好（Soft Affinity），意思是「调度器尽量把 Pod 调度到符合这些偏好的节点上，但如果没有满足条件的节点，也不会阻止调度」，是调度时的倾向性选项，不是硬性约束。

字段结构：

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

示例：

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

### 硬亲和性

`requiredDuringSchedulingIgnoredDuringExecution`是 Kubernetes Pod 的调度约束中的一个字段，用来指定 Pod 只能被调度到符合特定节点标签要求的节点上。

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

## 二、Pod Affinity（Pod 亲和性）

