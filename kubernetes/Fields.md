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
| nodeSelector | map\[string]string | 否 | 用于给 Pod 指定简单的节点选择条件，告诉调度器只把 Pod 调度到符合标签要求的节点上。|
| os | string | 否 | 该字段用于多操作系统混合集群（例如同时有 Linux 和 Windows 节点）时，告诉调度器该 Pod 需要运行的操作系统|
| overhead | map\[string]Quantity | 否 | 指定 Pod 运行时除容器资源外需要预留的额外资源（例如 sandbox 资源消耗）|
| preemptionPolicy | string | 否（默认 PreemptLowerPriority）| 抢占（Preemption） 是 Kubernetes 调度器在资源紧张时让高优先级 Pod 挤掉低优先级 Pod 的机制。|
| priority | integer | 否 | 指定 Pod 的优先级数值，数值越大优先级越高|
| priorityClassName | string | 否（默认无，优先级为 0）| 指定 Pod 使用的优先级类别名称，间接确定 Pod 优先级数值 |
| readinessGates | \[]PodReadinessGate | 否（默认无）| 定义额外的自定义条件，Pod 只有所有条件都满足时才算 Ready |
| resourceClaims | \[]PodResourceClaim | 否（默认无）| 绑定 Pod 需要的动态分配资源，类似 PersistentVolumeClaim 但用于设备资源 |
| resources | ResourceRequirements | 否（但建议明确配置以保证调度合理）| 指定容器的 CPU、内存等资源的请求（requests）和限制（limits）|
| restartPolicy | string |  否（默认 Always）| 控制容器失败后的重启行为: Always、OnFailure、Never |
| runtimeClassName | string | 否（默认使用集群默认运行时）| 指定 Pod 运行时类别，选择不同的容器运行时实现（例如不同的 sandbox 或隔离方式）|
| schedulerName | string | 否（默认值为 default-scheduler）| 指定 Pod 使用哪个调度器进行调度决策 |
| schedulingGates | \[]PodSchedulingGate | 否（默认不设置）| 用于控制 调度的延迟，即人为设置一个“等待点”，让 Pod 暂时不参与调度，直到你明确解除这个限制。|
| securityContext | PodSecurityContext |  否 | 定义 Pod 中所有容器共享的安全设置（如用户 ID、权限、主机访问策略等）|
| serviceAccountName | string | 否（不指定则默认使用 default ServiceAccount）| 指定 Pod 使用的 ServiceAccount，从而控制其访问 Kubernetes API 的权限）|
| setHostnameAsFQDN | boolean | 否（默认值：false）| 控制 Pod 的主机名是否设置为其 FQDN（即 hostname.namespace.svc.cluster.local）|
| shareProcessNamespace | boolean | 否（默认值：false）| 用于控制 Pod 中的容器是否共享同一个 进程命名空间（Process Namespace）|
| subdomain | string | 否 |subdomain 是 Pod.spec.hostname 和 Pod.spec.subdomain 一起使用时的一个字段，主要用于为 Pod 设置稳定的 DNS 域名。这是 Stateful 应用（例如数据库、副本集群等）中常用的功能。|
| terminationGracePeriodSeconds | integer | 否（默认值：30s） | 是 Pod 规范 (Pod.spec) 中的一个重要字段，用于控制 Pod 在终止前的“优雅退出”时间。它指定了容器在收到终止信号（SIGTERM）之后，有多少秒时间去清理资源、保存状态或完成正在执行的任务。|
| tolerations | []Toleration | 否 |tolerations 是 Pod 的一个字段，用于让 Pod “容忍”节点上的 taint（污点），从而可以被调度到这些带有特殊限制的节点上。|
| topologySpreadConstraints | \[]TopologySpreadConstraint | 否 | 用来控制 Pod 如何均匀地分布在集群节点的不同拓扑域中，以提升应用的高可用性和容错性。|
| volumes | \[]Volume | 否 | 定义了 Pod 中容器可以挂载的存储资源。volumes 负责抽象不同类型的存储，方便容器访问和持久化数据。|

### affinity

在 Kubernetes 中，Pod.spec.affinity 是用来定义 Pod 的调度亲和性（affinity）和反亲和性（anti-affinity）规则的字段，用于控制 Pod 在哪些节点（Node）上调度或避免调度。它可以帮助优化 Pod 的部署位置，提升集群资源利用率、性能或高可用性。

**三种调度规则：**

1. nodeAffinity (节点亲和性)
    - preferredDuringSchedulingIgnoredDuringExecution (软性调度偏好)
    - requiredDuringSchedulingIgnoredDuringExecution （硬性调度）

**软性调度偏好结构：**

```yaml
- weight: <int>        # 权重（1-100），表示优先级
  preference:          # 匹配节点的选择器规则
    matchExpressions:  # 表达式方式选择节点
      - key: <string>
        operator: <In|NotIn|Exists|DoesNotExist|Gt|Lt>
        values: [<string>]
```

示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-demo
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
        - weight: 20
          preference:
            matchExpressions:
              - key: zone
                operator: In
                values:
                  - zoneA

```

> [!NOTE]
>
> - 优先调度到标签 disktype=ssd 的节点，优先级 80。
> - 如果多个节点都满足或没有满足上面条件，则进一步优先考虑 zone=zoneA，优先级 20。
> - 但如果都不满足，这些规则会被 忽略，仍然会调度成功。

**硬性调度结构:**

```yaml
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: <string>
          operator: <In|NotIn|Exists|DoesNotExist|Gt|Lt>
          values: [<string>]
```

示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: required-affinity-demo
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
              - key: cpu
                operator: Gt
                values:
                  - "4"
          - matchExpressions:
              - key: zone
                operator: In
                values:
                  - zoneA
```

> [!NOTE]
>
> - Pod 只能调度到满足以下 任一 条件的节点：
>   - 条件 A：节点具有 disktype=ssd 且 cpu > 4；
>   - 条件 B：节点标签 zone=zoneA；
>
> 如果没有符合这两个条件中任意一个的节点，Pod 就会处于 Pending 状态，直到有满足的节点。

**常见的使用方法：**

硬性规则：调度器首先根据 requiredDuringSchedulingIgnoredDuringExecution 筛选出“合格节点集合”。
软性规则：再在合格节点中，根据 preferredDuringSchedulingIgnoredDuringExecution 的权重排序，选出“最优节点”进行调度。

示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: combined-affinity-demo
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: node-type
                operator: In
                values:
                  - compute
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 90
          preference:
            matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
        - weight: 10
          preference:
            matchExpressions:
              - key: zone
                operator: In
                values:
                  - zone-a
```

> [!TIP]
>
> - 这个 Pod 只能调度到标签 node-type=compute 的节点上（硬性要求）。
> - 如果有多个符合的节点，调度器会优先选择具有 disktype=ssd 的节点；
> - 如果仍有多个候选，次优选 zone=zone-a 的节点；
> - 如果没有满足软性条件的节点，只要满足硬性条件，仍然会调度。


2. podAffinity (Pod亲和性)


3. podAntiAffinity (Pod反亲和性)