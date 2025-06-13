# ds.spec

`DaemonSet`控制器规格描述文档。

## ds.spec.selector

有效字段及值：

### matchExpressions `<[]LabelSelectorRequirement>`

匹配表达式包含以下字段：

|字段|类型|说明|
|----|----|----|
|`matchExpressions`|`<[]LabelSelectorRequirement>`|匹配表达式，列表之间关系为`AND`与关系|
|`matchLabels`|`<map[string]string>`|匹配标签，一个包含 {key,value} 对的映射。逻辑关系为`AND`与关系|

