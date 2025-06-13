# Pod资源

Pod 是 Kubernetes 中可以部署的最小单位。

它包含了一个或多个容器，这些容器共享同一个网络和存储环境，彼此紧密绑定，就像“在一台机器上的进程群”。

## 网络

- Pod 内部的容器可以通过 localhost 直接通信。

- Pod 有自己的 IP 地址（由 CNI 插件提供）。

- Pod 之间不能通过 localhost 通信，要用服务（Service）进行连接。

## 生命周期

Pod 的生命周期是短暂的，不可变的。如果 Pod 被删除或崩溃：

- 它会被新的 Pod 替代（但不是“原地复活”，是一个新的 Pod）

- Pod 的 IP 地址会变

所以如果需要“长期存在”的服务，要配合 Deployment 或 StatefulSet 来管理 Pod。

## 字段结构

|字段|类型|描述|
|---|----|----|
|`apiVersion`|`<string>`|值：`v1`|
|`kind`|`<string>`|值：`Pod`|
|`metadata`|`<ObjectMeta>`|元数据部分，用于标识和管理对象。|
|`spec`|`<PodSpec>`|Pod 的核心部分，定义运行什么、怎么运行。|
|`status`|`<PodStatus>`|Pod最近运行状态，可能不是最新的数据。由系统填充/只读。|

### metadata

|字段|类型|描述|
|---|----|----|
|`annotations`|`<map[string]string>`|用来给 Pod 添加非结构化附加信息的字段。与 labels 不同，annotations 不参与选择器匹配，主要用于工具、系统或人类读取用。|
|`creationTimestamp`|`<string>`|资源在 Kubernetes API Server 上被成功创建的时间。由系统自动设置，只读字段，用户不能修改。|
|`deletionGracePeriodSeconds`|`<integer>`|Pod 被删除时允许其优雅终止的时间（秒），之后如果未终止，系统会强制 kill。|
|`deletionTimestamp`|`<string>`|Pod 被请求删除的时间点。此时 Pod 不会马上消失，而是进入“终止”流程。|
|`finalizers`|`<[]string>`|资源在被删除之前必须先完成的一组“清理”任务列表。只有当所有 finalizer 被清除，资源才会真正从 etcd 中删除。|
|`generateName`|`<string>`|创建资源时自动生成的名称前缀，系统会基于它生成一个唯一的资源名。|
|`generation`|`<integer>`|自资源创建以来，spec 字段被修改的次数。系统填充/只读|
|`labels`|`<map[string]string>`|用于给资源添加一组键值对（key-value pairs），用以标识、分类和筛选资源。|
|`managedFields`|`<[]ManagedFieldsEntry>`|主要用于记录对象的“字段管理历史”，即告诉你哪些字段由哪个管理者（Controller、用户、工具）在什么时候以何种操作方式更新的。 系统自动生成和维护的，普通用户和开发者通常不需要手动填写或修改它。|
|`name`|`<string>`|资源名称，名称在命名空间内必须是唯一的。|
|`namespace`|`<string>`|设置该资源所在的命名空间|
|`ownerReferences`|`<[]OwnerReference>`|指向拥有该资源的上级资源列表，支持级联删除和资源追踪。由 Kubernetes 控制器或 API 自动设置，用户通常不需要手动维护。|
|`resourceVersion`|`<string>`|用来表示该资源在 etcd 中的版本号（或者说是资源的“修改版本标识”）。系统填充/只读|
|`selfLink`|`<string>`|用来表示该资源对象在 Kubernetes API 中的唯一访问路径（URL）。己废弃|
|`uid`|`<string>`|资源的全局唯一标识符（UUID格式）系统填充/只读|