# 污点和容忍度

在 Kubernetes 中，“污点（Taints）” 和 “容忍度（Tolerations）” 是一对机制，用来控制 Pod 可以被调度到哪些节点 上。简单来说，它们是用来做“节点隔离”或“节点选择”控制的。

- 污点（Taint） 是给 节点 贴的“不欢迎某些 Pod”的标签
- 容忍度（Toleration） 是 Pod 表示“我能接受这个标签”的声明。

> [!NOTE]
> 只有 Pod 的容忍度匹配节点的污点，Pod 才能被调度到这个节点上。

## 污点格式

污点由三个部分组成：

```bash
key=value:effect
```

给节点添加污点：

```bash
kubectl taint nodes node1 key1=value1:NoSchedule
```

表示给节点 node1 添加了一个污点：

- key1=value1 是自定义的键值
- NoSchedule 是一个效果（effect）

### effect类型

|effect|描述|
|------|---|
|NoSchedule|除非 Pod 容忍这个污点，否则不会被调度到这个节点上|
|PreferNoSchedule|尽量不要调度到有这个污点的节点，但不是强制|
|NoExecute|不仅不调度，还会驱逐（Evict）已经在上面的 Pod，除非容忍|

## 容忍度格式

容忍度写在 Pod 的 spec.tolerations 字段中，形式如下：

```ymal
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
```

表示 Pod “容忍”这种污点，所以能调度到有这个污点的节点上。

### operator值

容忍度中的operator一共有两个值：

1. Equal（默认）, Pod 容忍某个具体 key=value 的污点。
2. Exists，Pod 容忍具有某个 key 的污点， 不管污点的 value 是什么。

## 举例场景

**场景一:**
比如你有一台节点专门跑系统类的 Pod，或者专门跑 GPU 任务的节点，你可以：

给该节点加一个污点：gpu=true:NoSchedule

只有加了相应 tolerations 的 Pod 才能调度进去

**场景二:**
Kubernetes 会自动给不健康的节点添加 NoExecute 的污点，用来把 Pod 驱逐到其他节点。