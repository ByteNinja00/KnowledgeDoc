# 存储

为集群中的 Pods 提供长期和临时存储的方法。

## Volume(卷)

卷为 Pod 中的容器提供了一种通过文件系统访问和共享数据的方式。

是 Pod 级别的卷（volume）定义，表示 Pod 中容器可挂载的存储资源。它是在 Pod 级别声明的，然后在 container.volumeMounts 中挂载使用。

**类型：**

通过`kubectl explain pod.spec.volumes`即可查看该对象下有哪些类型。

|字段|类型|描述|
|----|---|----|
|configMap|\<ConfigMapVolumeSource>|用于将 ConfigMap 资源挂载到 Pod 中的一种配置方式。通过 ConfigMap，你可以将配置数据（键值对、文件等）以卷的形式挂载到 Pod 的容器中，供容器内的应用程序使用。|
|csi|\<CSIVolumeSource>|它是一个标准化的接口，用于在容器编排系统（如 Kubernetes）与存储系统之间提供一致的存储管理方式。|
|downwardAPI|\<DownwardAPIVolumeSource>|用于将 Pod 或容器相关元数据（如 Pod 名称、命名空间、标签、注解等）以环境变量或文件的形式注入到容器中的机制。|
|emptyDir|\<EmptyDirVolumeSource>|emptyDir 是一个临时的、空的卷，在 Pod 创建时分配，并在 Pod 删除时销毁。它的内容在 Pod 运行期间可以被容器读写，适合临时数据存储。|
|ephemeral|\<EphemeralVolumeSource>|Ephemeral Volumes 是与 Pod 生命周期绑定的临时存储卷，Pod 删除后数据会丢失。它们扩展了 emptyDir 的功能，允许更灵活的配置，例如通过 generic ephemeral volumes 使用 StorageClass 动态分配存储。|
|fc|\<FCVolumeSource>|fc 卷允许 Pod 挂载通过光纤通道协议访问的存储设备。光纤通道是一种高性能存储网络协议，常用于企业级存储区域网络（SAN）。|
|hostPath|\<HostPathVolumeSource>|将节点主机的文件系统目录作为Pod内容器共享|
|image|\<ImageVolumeSource>|image 卷源代表一个在 kubelet 主机上可用的 OCI 对象（容器镜像或工件）。1.33beta特性默认关闭|
|iscsi|\<ISCSIVolumeSource>|用于将 iSCSI 存储挂载到 Pod 中。适用于需要高性能块存储的场景。|
|name|\string|卷的名称。必须是 DNS_LABEL 类型，并且在 Pod 内唯一。|
|nfs|\<NFSVolumeSource>|允许 Pod 挂载远程 NFS 服务器的共享目录。|
|persistentVolumeClaim|\<PersistentVolumeClaimVolumeSource>|它允许用户（或 Pod）声明对存储的需求（例如大小、访问模式），而无需直接管理底层的存储实现（如 NFS、iSCSI）。PVC 与 PersistentVolume（PV）配合使用，PV 定义实际的存储资源，PVC 则是对这些资源的请求。|
|projected|\<ProjectedVolumeSource>|是一种特殊的卷类型，用于将多种来源的数据（如 Secret、ConfigMap 或 Downward API）投射到同一个目录中，方便 Pod 内的容器访问。|
|secret|\<SecretVolumeSource>|用来给 Pod 传递敏感信息，例如密码。你可以将 Secret 存储在 Kubernetes API 服务器上，然后以文件的形式挂载到 Pod 中，无需直接与 Kubernetes 耦合。 secret 卷由 tmpfs（基于 RAM 的文件系统）提供存储，因此它们永远不会被写入非易失性（持久化的）存储器。|
