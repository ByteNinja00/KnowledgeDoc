# metadata字段

在 Kubernetes 中，Pod 资源的 metadata 对象用于提供关于 Pod 的元数据信息，这些信息通常用于标识、组织和管理 Pod。metadata 字段是 Kubernetes 资源对象的标准字段，定义在 Pod 的 YAML 或 JSON 配置文件中。以下是 Pod 资源中 metadata 对象的常见字段及其说明：

|字段名|类型|描述|
|-----|----|----|
|annotations|map[string]string|用于存储非结构化信息，不参与调度逻辑，主要给人或工具看|
|creationTimestamp|string|创建时间，只读，由系统填充|
|deletionGracePeriodSeconds|integer|此对象在从系统中删除之前允许正常终止的秒数。仅在设置了删除时间戳 (deletionTimestamp) 时才设置。只能缩短。只读。|