# ds.spec

`DaemonSet`控制器规格描述文档。

## ds.spec.selector

有效字段及值：

|字段|类型|说明|
|----|----|----|
|`matchExpressions`|`<[]LabelSelectorRequirement>`|匹配表达式，列表之间关系为`AND`与关系|
|`matchLabels`|`<map[string]string>`|匹配标签，一个包含 {key,value} 对的映射。逻辑关系为`AND`与关系|

### ds.spec.selector.matchExpressions

- key: `<string> -required-` labels的键名。
- operator: `<string> -required-` 操作符：`In`, `NotIn`, `Exists`，`DoesNotExist`。
- values: `<[]string>` labels的键值。

## ds.spec.template

定义DaemonSet管理的Pod模板，有效字段：

|字段|类型|说明|
|----|----|----|
|metadata|`<ObjectMeta>`|[metadata](/kubernetes/explain/Pod.md#metadata)|
|[spec](/kubernetes/explain/Pod.md#spec)|`<PodSpec>`|Pod模板规格|

## ds.spec.updateStrategy

有效字段及值：

|字段|类型|说明|
|----|----|----|
|rollingUpdate|`<RollingUpdateDaemonSet>`|滚动更新策略|
|type|`<string>`|DaemonSet 更新策略类型|

### ds.spec.updateStrategy.type

- RollingUpdate(默认)
  
  滚动更新：控制器逐个地重建每个节点上的 Pod，以尽量保持系统稳定不中断服务。

- OnDelete
  
  不自动更新 Pod。只有当你手动删除 Pod 时，DaemonSet 才会用新模板重新创建它。

### ds.spec.updateStrategy.rollingUpdate

- maxUnavailable

  表示 在更新期间，最多允许多少个 DaemonSet Pod 处于不可用状态（即未就绪）。
  
  可以是绝对值（整数）或百分比（字符串）。
