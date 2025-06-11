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
|name|\<string>|卷的名称。必须是 DNS_LABEL 类型，并且在 Pod 内唯一。|
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

### downwardAPI

downwardAPI 是 Kubernetes 提供的一种机制，用于将 Pod 自身的元数据信息（如 Pod 名称、Namespace、标签、注解、资源限制等）注入到容器内。你可以通过两种方式使用 downwardAPI：

1. 作为 环境变量
2. 作为 挂载文件（卷方式）

- defaultMode \<integer>

  用于设置挂载到容器文件系统中的文件权限（mode）。它控制 ConfigMap 中的所有文件的默认权限。`items`如果设置将被覆盖。
  
  以八进制数表示，通常写法是 0644 或 0755（前导0不可省略，否则可能被解析成十进制）。

- items \<[]DownwardAPIVolumeFile>

  用来定义 具体要通过 Downward API 挂载哪些 Pod 元数据信息（字段）到容器的哪些文件中。

  | 字段名                | 说明                                    |
  | ------------------ | ------------------------------------- |
  | `path`             | 必填，挂载文件的相对路径，写入卷挂载目录里的文件名             |
  | `fieldRef`         | 可选，从 Pod 元数据字段获取值（Downward API 的核心方式） |
  | `resourceFieldRef` | 可选，从 Pod 资源请求或限制中获取值（CPU、内存等）         |
  | `mode`             | 可选，为当前文件设置权限（覆盖 `defaultMode`）        |

  ```yaml
  volumes:
  - name: podinfo
    downwardAPI:
      items:
      - path: "pod_name"               # 文件名，挂载到容器内卷里的相对路径
        fieldRef:
          fieldPath: metadata.name     # Pod 元数据字段，Pod 名称
      - path: "pod_namespace"
        fieldRef:
          fieldPath: metadata.namespace
      - path: "cpu_limit"
        resourceFieldRef:
          resource: limits.cpu         # 资源限制字段，CPU 限制
          divisor: "1000m"             # 可选，转换单位，比如将 CPU 毫核转换成核
  ```

### emptyDir

emptyDir 是 Kubernetes Pod 中一种常用的卷类型，表示一个临时的空目录卷，在 Pod 启动时创建，Pod 生命周期内存在，Pod 终止后数据丢失。

- medium

  用来指定这个临时卷的存储介质类型。

  | 值        | 说明                    |
  | -------- | --------------------- |
  | `""`（空）  | 默认，使用节点本地磁盘作为存储介质。    |
  | `Memory` | 使用内存作为存储介质，挂载为 tmpfs。 |

  默认磁盘存储：
  
  ```yaml
  volumes:
  - name: cache-volume
    emptyDir: {}
  ```

  使用内存（tmpfs）：
  
  ```yaml
  volumes:
  - name: fast-cache
    emptyDir:
      medium: Memory
  ```
  
- sizeLimit

  sizeLimit 是 Kubernetes 中 emptyDir 卷的一个可选字段，用来限制该卷（尤其是内存型 emptyDir）最大可使用的存储空间大小。

  ```yaml
  volumes:
  - name: cache-volume
    emptyDir:
      medium: Memory
      sizeLimit: 1024Mi
  ```

### ephemeral

ephemeral 卷是随 Pod 生命周期创建和销毁的卷，Pod 删除时数据也随之销毁，和`emptyDir`不同的是`ephemeral`卷支持多种卷插件，比如 CSI 驱动的临时卷。

[参考官方文档](https://kubernetes.io/zh-cn/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes)

### hostPath

- path

  在节点主机上的目录路径。

- type

  用于指定或验证挂载路径类型，常用值包括：

  | 值                   | 含义                     |
  | ------------------- | ---------------------- |
  | `""` 或不设置           | 不检查类型，直接挂载             |
  | `Directory`         | 必须是已存在的目录              |
  | `DirectoryOrCreate` | 如果不存在，则创建目录            |
  | `File`              | 必须是已存在的文件              |
  | `FileOrCreate`      | 如果不存在，则创建空文件           |
  | `Socket`            | 必须是已存在的 Unix Socket 文件 |
  | `CharDevice`        | 必须是字符设备文件              |
  | `BlockDevice`       | 必须是块设备文件               |

示例：

```yaml
volumes:
- name: host-volume
  hostPath:
    path: /var/log/myapp        # 宿主机路径
    type: DirectoryOrCreate     # 类型，存在时验证类型，不存在则创建目录
```

### nfs

有效的字段：

|字段|类型|描述|
|----|----|----|
|path|\<string> -required-|nfs导出的共享路径|
|readOnly|\<boolean>|是否只读，默认false即读写模式|
|server|\<string> -required-|nfs服务的主机名或IP地址|

```yaml
volumes:
- name: nfs-volume
  nfs:
    server: 10.0.0.5               # NFS 服务器 IP 或主机名
    path: /exports/shared-data    # NFS 上共享的目录路径
    readOnly: false               # 是否只读挂载（默认 false）
```

### persistentVolumeClaim

有效的字段：

|字段|类型|描述|
|----|----|----|
|claimName|\<string> -required-|pvc资源对象的名称|
|readOnly|\<boolean>|控制Pod内容器对该持久卷的访问模式，默认false即读写模式，如果打开true则为只读模式|

### projected

有效的字段：

|字段|类型|描述|
|----|----|----|
|defaultMode|\<integer>|默认权限模式，影响文件的权限（如 0644）|
|sources|\<[]VolumeProjection>|填，包含多个子来源（configMap、secret、downwardAPI、serviceAccountToken）|

```yaml
volumes:
- name: combined-volume
  projected:
    sources:
    - configMap:
        name: app-config
    - secret:
        name: app-secret
    - downwardAPI:
        items:
        - path: "pod_name"
          fieldRef:
            fieldPath: metadata.name
    - serviceAccountToken:
        path: "token"
        expirationSeconds: 3600
```

### secret

有效的字段：

|字段|类型|描述|
|----|----|----|
|defaultMode|\<integer>|默认权限模式，影响文件的权限（如 0644）|
|items|\<[]KeyToPath>| 用于精确控制挂载某个 Secret 中的哪些键值对以及它们在容器文件系统中的路径。|
|optional|\<boolean>|在 Kubernetes 中，optional 是某些卷类型（如 secret、configMap、downwardAPI、projected 等）中用于表示：当指定的数据资源不存在时，Pod 是否仍然可以启动。默认为false，即不存在时Pod将启动失败。|
|secretName|\string|是用来指定要挂载的 Secret 资源名称。|

- secret.items 有效的值：

  | 字段名    | 说明                     |
  | ------ | ---------------------- |
  | `key`  | 指定 Secret 中的某个键名（必须存在） |
  | `path` | 容器中该键值挂载成的文件路径，相对于挂载目录 |
  |`mode`|设置挂载文件的权限,如果设置将覆盖defaultMode设置的值|

```yaml
volumes:
- name: my-secret-vol
  secret:
    secretName: my-secret
    items:
    - key: username
      path: my-app-user
    - key: password
      path: credentials/pass.txt
```

## PersistentVolume（PV）

在 Kubernetes 中，PersistentVolume（PV） 是集群级别的资源，用于为容器提供 独立于 Pod 生命周期的持久化存储。你可以把它理解为“集群中的硬盘”，用户通过 PersistentVolumeClaim（PVC） 来申请使用它。

### 特性

| 特性                                | 说明                                 |
| --------------------------------- | ---------------------------------- |
| **生命周期独立于 Pod**                   | Pod 被删除，PV 中的数据仍然保留（视回收策略而定）       |
| **由管理员预先创建，或由 StorageClass 动态生成** | 支持静态和动态两种方式                        |
| **支持多种存储后端**                      | NFS、iSCSI、Ceph、EBS、GlusterFS、本地磁盘等 |
| **通过 PVC 绑定使用**                   | 用户不能直接使用 PV，必须通过 PVC 来申请绑定         |

### spec规格

在了解pv.spec规格之前，先清楚该pv资源对象有效的字段：

|字段|类型|描述|
|----|---|----|
|apiVersion|\<string>|有效值：v1|
|kind|\<string>|有效值：PersistentVolume|
|metadata|\<ObjectMeta>|[参考metadata](/kubernetes/PodFeilds.md#metadata)|
|spec|\<PersistentVolumeSpec>|期望该资源对象运行的行为及规格|
|status|\<PersistentVolumeStatus>|该资源对象的状态，由系统填充/只读|

> [!TIP]
> `pv.sepc` 和 `pod.spec.volumes` 几乎相同都是对存储的操作，不同的是 volume 是直接挂载使用，生产环境建议还是使用 **PV+PVC** 或 **storageClass+PVC**。

#### accessModes 

类型：\<[]string>

pv.spec.accessModes 是 Kubernetes 中 PersistentVolume（PV） 资源定义里的一个字段，用于指定该存储卷对 Pod 的访问方式。它是一个字符串数组（[]string），值表示该 PV 支持的访问模式。常见的访问模式有以下三种：

| 模式名称            | 英文全称            | 说明                                    |
| --------------- | --------------- | ------------------------------------- |
| `ReadWriteOnce` | Read-Write-Once | 单个 Node 上的单个 Pod 可以读写挂载该卷。其他节点不能同时挂载。 |
| `ReadOnlyMany`  | Read-Only-Many  | 多个 Pod 可以以只读方式挂载该卷，可跨 Node 使用。        |
| `ReadWriteMany` | Read-Write-Many | 多个 Pod 可以以读写方式挂载该卷，也可跨 Node 使用。       |

#### capacity

类型：\<map[string]Quantity>

capacity 是 PersistentVolume（PV）中一个非常关键的字段，它定义了该卷的容量（主要是存储空间）。这个字段位于 spec.capacity 下，是一个 key-value 映射，用来表示资源的“容量值”。

语法格式：

```yaml
spec:
  capacity:
    storage: 10Gi
```

#### local

类型：\<LocalVolumeSource>

Kubernetes 中的 local 卷是一种将主机本地存储（例如物理磁盘或分区）暴露为 PersistentVolume（PV）的机制。它适合延迟要求低、高 IOPS 的场景，但不支持跨节点调度。

可以和**nodeAffinity**配合使用。

有效的值：

|值|类型|描述|
|--|---|----|
|fsType|\<string>|要挂载的文件系统类型。它仅当 Path 为块设备时适用。必须是主机操作系统支持的文件系统类型。例如：“ext4”、“xfs”、“ntfs”。如果未指定，则默认值为自动选择文件系统。|
|path|\<string> -required-|指定本地磁盘或挂载点路径，例如 /mnt/disks/ssd1|

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node-1
```

#### mountOptions

类型：\<LocalVolumeSource>

一个可选字段，用来指定当这个 PV 被挂载到 Pod 中时，应使用的挂载参数（mount options）。这个字段的设置会影响底层存储卷是如何被挂载的，尤其是在使用 NFS、GlusterFS、CephFS 等网络文件系统或某些支持挂载参数的本地存储时非常有用。

#### nodeAffinity

类型：\<VolumeNodeAffinity>

[参考nodeAffinity](/kubernetes/inffinity.md#nodeaffinity) 与pod.spec.affinity.nodeAffinity不同之处在于`required`。

#### persistentVolumeReclaimPolicy

类型：\<string>

用来控制 当 PVC（PersistentVolumeClaim）释放掉这个 PV 后，这个卷会被如何处理。

| 值            | 含义                                               |
| ------------ | ------------------------------------------------ |
| `Retain`     | 保留卷和数据，需要手动回收或清理。适合重要数据或敏感环境。                    |
| `Delete`     | 自动删除底层存储资源（如云磁盘），适合临时数据。                         |
| `Recycle` ⚠️ | 用 `rm -rf /thevolume/*` 清空内容（**已弃用**，1.25 起彻底移除） |

#### volumeMode

volumeMode 是 Kubernetes 中 PersistentVolume（PV）和 PersistentVolumeClaim（PVC） 都可以设置的字段，用于定义 卷的挂载方式。这是一个关键参数，直接影响 Pod 如何访问持久化存储。

有效的值：

| 值                | 含义                       |
| ---------------- | ------------------------ |
| `Filesystem`（默认） | 以挂载一个文件系统的方式提供存储（如 ext4） |
| `Block`          | 以原始块设备方式提供，不格式化，不挂载文件系统  |

#### storageClassName

存储类名，storageClassName 如果在PV中指定的存储类，那么PVC也应该对应指定该存储类，否则PVC将不会绑定PV。

PV不设置storageClassName:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
  # 没有 storageClassName
```

匹配它的 PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""  # 必须写成空，才能匹配上上面的 PV
  resources:
    requests:
      storage: 5Gi
```

#### volumeAttributesClassName

用于结合 CSI（Container Storage Interface）驱动时，动态附加卷属性。它并不是 PersistentVolume 或 PersistentVolumeClaim 的基础字段，而是在 CSI 动态供给场景中，通过 VolumeAttributesClass 提供额外配置。

- 使用 volumeAttributesClassName

```yaml
apiVersion: storage.k8s.io/v1alpha1
kind: VolumeAttributesClass
metadata:
  name: gold-tier
spec:
  driverName: csi.my-storage.com
  parameters:
    performance: high
    compressed: "true"
```

> [!NOTE] driverName 必须和 StorageClass 中使用的 CSI driver 一致。

- PVC 中使用它

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: csi-storage
  volumeAttributesClassName: gold-tier  # 指向上面的属性类
```

- 用于手动预配置的 PV

  当你在 静态 PV 中手动指定 volumeAttributesClassName，Kubernetes 会将它的参数应用到该 PV 被挂载时的卷属性里（前提是该 CSI driver 支持）。这相当于提前在 PV 层绑定卷属性策略。

  ```yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
  name: static-csi-pv
  spec:
    capacity:
      storage: 10Gi
    accessModes:
      - ReadWriteOnce
    csi:
      driver: csi.my-storage.com
      volumeHandle: vol-12345
    volumeAttributesClassName: gold-tier
  ```

  这个配置的效果是：

  即使 PVC 没有写 volumeAttributesClassName；
  
  该 PV 在挂载时也会使用 gold-tier 对应的属性参数；
  
  这只适用于 CSI 类型的 PV。

## PersistentVolumeClaim（PVC）

PVC 是用户 请求存储资源的声明，就像 Pod 申请 CPU 和内存一样，PVC 用来申请一个存储卷。

可以把 PVC 理解为：

「我需要一个 10Gi、ReadWriteOnce、使用某个存储类型的存储卷」

PVC 是用户视角下的“我要”，而 PV 是管理员或系统提供的“我有”。

