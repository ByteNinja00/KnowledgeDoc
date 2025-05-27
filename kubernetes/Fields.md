# YAML文件定义资源字段参考

## metadata

在 Kubernetes 中，Pod 资源的 metadata 对象用于提供关于 Pod 的元数据信息，这些信息通常用于标识、组织和管理 Pod。metadata 字段是 Kubernetes 资源对象的标准字段，定义在 Pod 的 YAML 或 JSON 配置文件中。以下是 Pod 资源中 metadata 对象的常见字段及其说明：

| 字段名                          | 类型                    | 是否必填             | 说明                                                       |
| ---------------------------- | --------------------- | ---------------- | -------------------------------------------------------- |
| `name`                       | string                | 否（手动创建时建议填写）     | Pod 的名称。在 YAML 中手动创建对象时，推荐设置；自动创建（如通过 Deployment）时系统会生成。 |
| `namespace`                  | string                | 否（默认是 `default`） | Pod 所属的命名空间。如果不指定，则默认是 `default` 命名空间。                   |
| `labels`                     | map\[string]string    | 否                | 标签是 key-value 形式的元数据，通常用于选择器匹配，比如服务选择器、Deployment 等。     |
| `annotations`                | map\[string]string    | 否                | 注解是非结构化数据，不参与选择器匹配，但可用于存储辅助信息。                           |
| `uid`                        | string                | 否（系统生成）          | 唯一标识，由 Kubernetes 系统自动分配。只读字段。                           |
| `resourceVersion`            | string                | 否（系统生成）          | 资源版本号，用于监控和变更检测。只读字段。                                    |
| `generation`                 | int64                 | 否                | 资源的版本计数，表示期望状态变更的次数。主要用于控制器中。                            |
| `creationTimestamp`          | string                | 否                | 创建时间戳。只读字段。                                              |
| `deletionTimestamp`          | string                | 否                | 删除时间戳，用于控制优雅终止。只读字段。                                     |
| `deletionGracePeriodSeconds` | int64                 | 否                | 优雅终止前的等待秒数。通常与删除一起使用。                                    |
| `finalizers`                 | \[]string             | 否                | Finalizer 是用于资源删除前执行清理逻辑的机制。                             |
| `ownerReferences`            | \[]OwnerReference     | 否                | 指向控制器对象（如 ReplicaSet）的引用。用于实现级联删除。                       |
| `managedFields`              | \[]ManagedFieldsEntry | 否                | Kubernetes 内部用于记录哪个字段由谁管理。调试时可能会看到。                      |
|generateName                  |string                 | 否                | 指定对象名称的前缀，由 Kubernetes 自动拼接一个唯一后缀来生成最终的 metadata.name|

## spec

PodSpec 是对 Pod 期望行为的规范。它定义了 Pod 内部行为、容器、网络、存储等各种运行时配置。

| 字段名                             | 类型                       | 是否必填               | 说明                                                 |
| ------------------------------- | ------------------------ | ------------------ | -------------------------------------------------- |
| activeDeadlineSeconds           | integer                 | 否                  | 设置 Pod 的生命周期上限，超过这个时间就会被 Kubernetes 强制终止（类似“超时自动取消”机制）|
| affinity                        | Affinity                | 否                   | 用于调度控制，即指定 Pod 应该部署到哪些节点、与哪些 Pod 靠近或远离。它是对 nodeSelector 和 podAntiAffinity 的升级，支持更复杂的逻辑表达式。|
| automountServiceAccountToken | boolean                    | 否                    | AutomountServiceAccountToken 指示是否应自动挂载服务帐号令牌。|
| containers                    | \[]Container               | 必须                 | 定义 Pod 中的主业务容器及其运行行为 |
| dnsConfig                     | PodDNSConfig              | 否                    | 指定 Pod 的 DNS 参数。此处指定的参数将根据 DNSPolicy 合并到生成的 DNS 配置中。|
| dnsPolicy                     | string                    | 否                    | 决定 Pod 的 DNS 查询策略（是用集群内部 DNS、主机 DNS，还是自定义）|
| enableServiceLinks | boolean | 否（默认值为 true）| 用于控制是否自动将集群中与该 Pod 同一命名空间的 Service 生成环境变量注入到 Pod 中。|
| ephemeralContainers | \[]EphemeralContainer | 否 | 用于临时向正在运行的 Pod 中注入调试容器。这类容器不会在 Pod 启动时创建，也不会被正常的控制器（如 Deployment）管理，只用于调试和排障。|
| hostAliases | \[]HostAlias | 否 | HostAliases 是可选的主机和 IP 列表，如果指定，它们将被注入到 pod 的 hosts 文件中。|
| hostIPC | boolean | 否（默认：false）| Pod 内容器与 Node 共享 IPC（可访问宿主机上的 /dev/shm 等资源）|
| hostNetwork | boolean | 否（默认：false）| 用于控制 Pod 是否使用 宿主机（Node）的网络命名空间。当设置为 true 时，Pod 中所有容器将与 Node 共用网络栈 —— 包括 IP 地址、端口空间、路由表等。|
| hostPID | boolean | 否（默认：false）| Pod 内容器与宿主机共享 PID 命名空间，可以看到宿主机和所有 Pod 上运行的进程 |
| hostUsers | boolean | 否（默认：false）| Pod 与宿主机共享用户命名空间，UID/GID 对应宿主机用户权限 |
| hostname | string | 否 | Pod 内所有容器的主机名均为该字段值，如果不设置，Pod 的主机名是 Pod 名称|
| imagePullSecrets | \[]LocalObjectReference | 否 | 用来指定私有镜像仓库认证信息的字段。|
| initContainers | \[]Container | 否 | 定义初始化容器，按顺序运行，成功后再启动主容器，每个 initContainer 必须成功退出后才启动下一个；失败会重试 |
| nodeName | string | 否 | 直接指定 Pod 运行的节点名称，绕过调度器调度, Pod 直接被绑定到指定节点，不参与调度决策 |
| nodeSelector | map[string]string | 否 | 用于给 Pod 指定简单的节点选择条件，告诉调度器只把 Pod 调度到符合标签要求的节点上。|
