# 污点和容忍度

Kubernetes 中的 污点（Taints） 和 容忍度（Tolerations） 是一种 调度控制机制，用于限制某些 Pod 被调度到特定的节点上，或者允许某些 Pod 忽略节点的不利条件。

## 污点

污点用于标记节点“不欢迎”某些 Pod 调度到该节点上。

```bash
kubectl taint nodes node1 status=unavailable:NoSchedule
```

> [!TIP]
> 在`node1`上标记了污点键值为：`status=unavailable`影响效果为`NoSchedule`不可调度。

### 污点效果（Effect）

| Effect             | 说明                        |
| ------------------ | ------------------------- |
| `NoSchedule`       | 不允许没有相应容忍度的 Pod 被调度到该节点上。 |
| `PreferNoSchedule` | 尽量不调度，但不是强制的。             |
| `NoExecute`        | 不仅不调度，还会驱逐现有不容忍该污点的 Pod。  |

## 容忍度（Tolerations）

Pod 通过 tolerations 允许自己被调度到带有特定污点的节点上。

容忍度在`pod.spec.tolerations`字段下，是一个`<[]Toleration>`列表类型。

| 字段 |   类型    | 描述                                                                           |
|:-----|:---------|:-------------------------------------------------------------------------------|
|effect|`<string>`|[参考污点效果](/kubernetes/explain/Scheduler/taints-tolerations.md#污点效果effect)|
|key|`<string>`|匹配节点污点的键名|
|operator|`<string>`|操作符: `Equal`(等于，配和键-值)，`Exists`(存在，某个键存在即匹配成功)|
|tolerationSeconds|`<integer>`|只在 NoExecute 类型污点时才起作用 的字段，用于控制：od 在遇到 NoExecute 污点时，可以在节点上停留多久，然后被驱逐（evict）。|
|value|`<string>`|匹配节点污点的键值|
