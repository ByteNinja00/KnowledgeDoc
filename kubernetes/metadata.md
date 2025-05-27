# Pod资源YAML文件字段

## metadata字段

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

## spec字段

