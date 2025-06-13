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