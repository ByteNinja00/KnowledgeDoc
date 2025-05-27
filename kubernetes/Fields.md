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
| `containers`                    | `[]Container`            | ✅ 是                | 定义 Pod 中的主容器列表。至少需要一个。每个容器定义镜像、端口、命令等。             |
| `initContainers`                | `[]Container`            | 否                  | 在主容器启动前依次执行的容器，常用于初始化任务。                           |
| `volumes`                       | `[]Volume`               | 否                  | 为容器挂载的卷列表，支持多种类型（如 emptyDir、hostPath、configMap 等）。 |
| `restartPolicy`                 | `string`                 | 否（默认 Always）       | 容器崩溃后的重启策略，可选值：`Always`、`OnFailure`、`Never`。       |
| `nodeSelector`                  | `map[string]string`      | 否                  | 通过标签选择调度到特定节点。                                     |
| `affinity`                      | `Affinity`               | 否                  | 定义更复杂的调度规则，如亲和性、反亲和性。                              |
| `tolerations`                   | `[]Toleration`           | 否                  | 与节点的 Taints 搭配使用，决定 Pod 是否可以容忍特定节点污点。              |
| `hostNetwork`                   | `bool`                   | 否                  | 是否使用宿主机网络。设置为 true 后，容器直接使用宿主机的 IP。                |
| `dnsPolicy`                     | `string`                 | 否（默认 ClusterFirst） | DNS 策略，控制容器内部 DNS 的行为。                             |
| `serviceAccountName`            | `string`                 | 否                  | 指定用于运行 Pod 的服务账户名称，影响 API 访问权限。                    |
| `imagePullSecrets`              | `[]LocalObjectReference` | 否                  | 拉取私有镜像时使用的密钥。                                      |
| `securityContext`               | `PodSecurityContext`     | 否                  | 设置 Pod 级别的安全上下文，如运行用户、FS 权限等。                      |
| `terminationGracePeriodSeconds` | `int64`                  | 否（默认 30）           | 优雅终止等待秒数。                                          |
| `hostAliases`                   | `[]HostAlias`            | 否                  | 手动设置 `/etc/hosts` 的域名解析。                           |
| `schedulerName`                 | `string`                 | 否                  | 指定调度器名称。默认是 kube-scheduler。                        |
