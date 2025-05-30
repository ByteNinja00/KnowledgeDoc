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