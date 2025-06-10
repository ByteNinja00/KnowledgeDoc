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

### configMap

- defaultMode \<integer>

  用于设置挂载到容器文件系统中的文件权限（mode）。它控制 ConfigMap 中的所有文件的默认权限。`items`如果设置将被覆盖。

- items \<[]KeyToPath>

  用来 指定挂载 ConfigMap 中部分 key，并且可以为这些 key 指定文件名和权限 的字段。
  
  - key: ConfigMap 中存在的某个数据项（文件名）
  - path: 容器挂载后该文件的路径，相对于挂载点目录
  - mode: （可选）权限，覆盖 defaultMode，使用八进制权限码

- name \<string>

  指定要挂载的 ConfigMap 名称

- optional

  如果设为 true，即使 ConfigMap 不存在，Pod 也能照样启动；设为 false（默认），ConfigMap 不存在就会让 Pod 报错重试。

**示例：**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config-volume      # ① 这里对应下面 volumes 里的 name
      mountPath: /etc/config   # ② 容器里挂载路径
  volumes:
  - name: config-volume        # ① 与 volumeMounts.name 一致
    configMap:
      name: my-config          # ③ 指定要挂载的 ConfigMap 名称
      items:
      - key:   application.properties
        path:  application.properties
      optional: false
```

### csi

Pod 中直接使用 CSI 卷（短期测试或调试时可用），生产环境建议使用 **StorageClass + PVC**

- driver \<string> -required-
  
  一定要与所部署的 CSI 插件注册时所声明的名称完全一致（可用 kubectl get csidrivers 查看）。

- fsType \<string>

  fsType 用来指定卷在节点上被格式化（或已经格式化）的文件系统类型。简单来说，它告诉 Kubelet 到底要用哪种文件系统去挂载这个设备。

  - ext4（Linux 下最常用）

  - xfs（高性能、大容量服务器常用）

  - btrfs

  - ntfs、vfat（实际上在 Linux 上也支持，主要给 Windows 兼容或小型 U 盘 用）

  具体取决于宿主节点的内核和CSI 驱动本身是否实现了格式化，建议优先选用 ext4 或 xfs。

- nodePublishSecretRef \<LocalObjectReference>

  nodePublishSecretRef 用来引用一个 Kubernetes Secret，该 Secret 存放了节点插件在 “Publish”（Attach/Mount）阶段所需的凭证或敏感配置。简而言之，它告诉 Kubelet “你去节点上操作这个卷时，需要用下面这个 Secret 里的字段来认证／授权。”

  ```yaml
  volumes:
  - name: secure-data
    csi:
      driver: example.com/my-csi-driver
      volumeHandle: vol-12345
      fsType: ext4
    # ##############################
      nodePublishSecretRef:
        name: my-csi-node-secret      # ← Secret 名称
        namespace: storage-credentials # ← 可选，默认为 Pod 所在的 Namespace
    # ##############################
      volumeAttributes:
      ...  
  ```

- readOnly \<boolean>
  
  readOnly 用来控制这个卷在容器里是“只读”挂载还是“可读写”挂载。默认是false即读写模式。

- volumeAttributes \<map[string]string>

  volumeAttributes 是 Kubernetes 中 CSI 卷（csi 卷类型）里的一个可选字段，用来给 CSI 驱动传递自定义的键值对参数。这些参数通常会被 CSI 插件的 Controller 和 Node 组件读取，用于控制存储卷的创建、配置或挂载行为。
