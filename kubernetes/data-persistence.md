# 数据持久化

Kubernetes 中的数据持久化（Persistence）是指在 Pod 生命周期之外保留和恢复数据的能力。这是确保有状态应用（如数据库、日志服务等）可靠运行的关键。

## 基本结构

volumes 是 spec 下的一个列表，每一项都是一个 volume 对象：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  volumes:
    - name: my-volume
      emptyDir: {}        # 这里定义卷的类型和配置
  containers:
    - name: my-container
      image: busybox
      volumeMounts:
        - mountPath: /data
          name: my-volume
```

## 存储资源类型

> [!NOTE]
> 在kubernetes1.32版本中，许多云厂商的存储资源类型己被弃用，改用 **CSI(Container Storage Interface)** 作为驱动动态挂载任意存储后端（如 rook-ceph、阿里云、AWS EBS 等）。

|字段      |类型                    |描述                                                                                                           |
|---------|------------------------|---------------------------------------------------------------------------------------------------------------|
|name|string|必须指定卷名|
|[configMap](/kubernetes/data-persistence.md#configmap)|\<ConfigMapVolumeSource>|用于将一个 ConfigMap 中的数据以文件的形式挂载到容器中。适用于将配置信息从 ConfigMap 注入容器，比如配置文件、启动参数等。|
|[csi](/kubernetes/data-persistence.md#csi)|\<CSIVolumeSource>|用于连接各种第三方或云平台的存储系统。|
|[downwardAPI](/kubernetes/data-persistence.md#downwardapi)|\<DownwardAPIVolumeSource>|用来将 Pod 的元数据信息（如标签、名称、资源限制等） 以文件的形式挂载进容器。这使得容器可以感知自身的运行信息，不需要通过 API Server 访问。|
|[emptyDir](/kubernetes/data-persistence.md#emptydir)|\<EmptyDirVolumeSource>|定义的一种临时存储卷类型。在 Pod 生命周期内共享存储用得最多的就是它，尤其是在容器之间需要共享临时文件时。|
|[ephemeral](/kubernetes/data-persistence.md#ephemeral)|\<EphemeralVolumeSource>|主要是为了支持 轻量级、临时的卷生命周期管理，本质上是一个对 EmptyDir、ConfigMap、Secret 等临时存储资源的抽象封装，符合 Pod 生命周期。|
|[fc](/kubernetes/data-persistence.md#fc)|\<FCVolumeSource>|fc 是 Fibre Channel（光纤通道）卷插件的缩写。它用于挂载基于光纤通道的块存储设备到 Pod 中。|
|[hostPath](/kubernetes/data-persistence.md#hostpath)|\<HostPathVolumeSource>|用于将 宿主机上的某个路径挂载到 Pod 中。非常直接且灵活，适用于一些需要访问宿主机资源的场景（如日志、Docker socket、配置文件、临时目录等）。|
|[image](/kubernetes/data-persistence.md#image)|\<ImageVolumeSource>|允许你把一个 OCI 镜像（不是容器） 里的文件系统内容 挂载为只读卷，供 Pod 使用。类似于使用一个容器镜像当成“只读 NFS”，但性能更好、集成更深。|
|[iscsi](/kubernetes/data-persistence.md#iscsi)|\<ISCSIVolumeSource>|，用于将 iSCSI 卷（块存储） 挂载进容器。iSCSI（Internet Small Computer Systems Interface）是一种通过网络访问远程存储设备的协议，常见于企业级存储系统中。|
|[nfs](/kubernetes/data-persistence.md#nfs)|\<NFSVolumeSource>|是用于挂载 NFS（Network File System）网络共享目录 的卷类型。它允许多个 Pod（甚至跨节点）共享同一套文件数据，是一种非常常见的共享存储解决方案|
|[persistentVolumeClaim](/kubernetes/data-persistence.md#persistentvolumeclaim)|\<PersistentVolumeClaimVolumeSource>|用于挂载一个 PersistentVolumeClaim（PVC）卷的字段。它允许 Pod 挂载之前通过 PVC 申请的持久存储，从而实现数据持久化和跨 Pod 共享。|
|[projected](/kubernetes/data-persistence.md#projected)|\<ProjectedVolumeSource>|它允许把多个 Secret、ConfigMap、DownwardAPI、ServiceAccountToken 等不同数据源的内容，以文件的形式挂载到同一个目录。|
|[secret](/kubernetes/data-persistence.md#secret)|\<SecretVolumeSource>|Pod 可以把 Secret 对象中的键值对挂载成文件，容器读取文件即可使用敏感信息。|

### configMap

将 ConfigMap 中的 key/value 对 挂载为文件，文件名为 key，内容为 value。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
spec:
  containers:
    - name: app
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config  # configMap 中的键值将作为文件挂载到这里
  volumes:
    - name: config-volume
      configMap:
        name: my-config  # 引用 ConfigMap 的名字
```

### csi

在 Pod 中直接通过 volumes.csi 使用已安装的 CSI 驱动提供的存储卷，无需预先创建 PVC，适合一些临时挂载、测试场景。但在生产中，推荐配合 PersistentVolume 和 PersistentVolumeClaim 使用（更常见）。

生产环境建议通过 PVC 使用 CSI:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: alicloud-disk-essd
  resources:
    requests:
      storage: 20Gi
```

然后在 Pod 中使用：

```yaml
volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

### downwardAPI

挂载 Pod 元数据:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downwardapi-pod
  labels:
    app: demo
spec:
  containers:
    - name: main
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
        - name: downward
          mountPath: /etc/podinfo
  volumes:
    - name: downward
      downwardAPI:
        items:
          - path: "pod-name"
            fieldRef:
              fieldPath: metadata.name
          - path: "pod-namespace"
            fieldRef:
              fieldPath: metadata.namespace
```

### emptyDir

```yaml
emptyDir:
  medium: ""        # 默认为 ""（即使用 Node 的磁盘）。可选值："Memory"
  sizeLimit: "1Gi"  # 可选字段，限制大小（从 Kubernetes 1.10 起支持）
```

### ephemeral

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ephemeral-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: ephemeral-vol
      mountPath: /data
  volumes:
  - name: ephemeral-vol
    ephemeral:
      volumeClaimTemplate:
        metadata:
          labels:
            type: ephemeral
        spec:
          accessModes: [ "ReadWriteOnce" ]
          resources:
            requests:
              storage: 1Gi
```

### fc

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fc-pod
spec:
  containers:
  - name: app
    image: busybox
    command: [ "sleep", "3600" ]
    volumeMounts:
    - name: fcvolume
      mountPath: /data
  volumes:
  - name: fcvolume
    fc:
      targetWWNs:
      - "50060e801049cfd1"
      - "50060e801049cfd2"
      lun: 0
      fsType: ext4
      readOnly: false
```

### hostPath

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: host-volume
      mountPath: /data
  volumes:
  - name: host-volume
    hostPath:
      path: /var/log
      type: Directory
```

### image

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: image-volume-pod
spec:
  containers:
  - name: main
    image: busybox
    command: [ "sh", "-c", "cat /mnt/data/README.md; sleep 3600" ]
    volumeMounts:
    - name: data
      mountPath: /mnt/data
  volumes:
  - name: data
    image:
      name: docker.io/library/mydata:latest
      pullPolicy: IfNotPresent
```

> [!TIP]
> Alpha 特性，kube-apiserver 和 kubelet 都必须开启以下特性门控（Feature Gate）：`--feature-gates=ImageVolumes=true`

### iscsi

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: iscsi-demo
spec:
  containers:
  - name: app
    image: busybox
    command: [ "sleep", "3600" ]
    volumeMounts:
    - mountPath: /mnt/iscsi
      name: iscsi-storage
  volumes:
  - name: iscsi-storage
    iscsi:
      targetPortal: 10.0.0.2:3260  # iSCSI Target IP 和端口
      iqn: iqn.2023-01.com.example:storage.disk1  # iSCSI 目标名称
      lun: 0
      fsType: ext4
      readOnly: false
```

### nfs

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-demo
spec:
  containers:
  - name: app
    image: busybox
    command: [ "sh", "-c", "sleep 3600" ]
    volumeMounts:
    - name: nfs-vol
      mountPath: /mnt/nfs
  volumes:
  - name: nfs-vol
    nfs:
      server: 10.0.0.100          # NFS 服务器 IP
      path: /data/k8s-share       # 导出的目录路径
      readOnly: false
```

### persistentVolumeClaim

- 定义一个PV（如 NFS、iSCSI、云盘等）

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: slow
  nfs:
    server: 10.0.0.100
    path: /data/k8s
```

- 定义一个 PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: slow
```

- Pod 使用 PVC：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-using-pvc
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - mountPath: /data
      name: data-vol
  volumes:
  - name: data-vol
    persistentVolumeClaim:
      claimName: pvc-nfs
```

### projected

```yaml
volumes:
- name: projected-volume
  projected:
    sources:
    - secret:
        name: my-secret
        items:
        - key: password
          path: password.txt
    - configMap:
        name: my-config
        items:
        - key: config.yaml
          path: config.yaml
    - downwardAPI:
        items:
        - path: labels
          fieldRef:
            fieldPath: metadata.labels
```

### secret

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: secret-vol
      mountPath: /etc/secret
      readOnly: true
  volumes:
  - name: secret-vol
    secret:
      secretName: my-secret
```

## PV

PersistentVolume（PV） 是由管理员预先创建的存储资源，它是 Kubernetes 存储抽象的一部分。Pod 通过 PersistentVolumeClaim（PVC）请求使用这些资源。

|字段|类型|描述|
|----|---|----|
|apiVersion|\<string>|Kubernetes API 版本，值为：`v1`|
|kind|\<string>|资源类型，值为：`PersistentVolume`|
|metadata|\<ObjectMeta>|该资源元数据，[参考Metadata](/kubernetes/PodFeilds.md#metadata)|
|spec|\<PersistentVolumeSpec>|PV 的详细规格，是最核心的部分。|
|status|\<PersistentVolumeStatus>|描述当前 PV 的状态，系统填充/只读|

### pv.spec

|字段|类型|描述|
|----|----|----|
|accessModes|、<[]string>|指定了该存储卷支持哪些访问模式（Access Modes）。|
|capacity|\<map[string]Quantity>|用于定义该卷可以提供的存储容量。这是 PV 的关键资源属性之一，主要由 PVC（PersistentVolumeClaim）来请求并匹配使用。|
|claimRef|\<ObjectReference>|这个字段是由 Kubernetes 控制器在 PVC 和 PV 成功绑定时自动填写的，你不需要手动指定它（除非你手动创建静态绑定，但那是高级用法）。|
|csi|\<CSIPersistentVolumeSource>|CSI 是 Container Storage Interface 的缩写，它是一种跨平台的标准接口，用于将存储系统（如 Ceph、NFS、iSCSI、LVM、云存储等）集成到 Kubernetes 这样的容器编排平台中。|
|mountOptions|\<[]string>|用于指定挂载卷时所使用的挂载参数（mount options），其作用类似于 mount 命令中的参数。这些参数会传递到底层的 mount 命令中，具体参数依据底层文件系统不同而异。|
|nodeAffinity|\<VolumeNodeAffinity>|用于定义卷的节点亲和性规则的字段，它控制 该 PV 可以在哪些节点上被挂载使用。|
|persistentVolumeReclaimPolicy|\<string>|用来定义 当 PVC 删除后，PV 应该如何处理。|
|storageClassName|\<string>|是 Kubernetes 中 PersistentVolume（PV）和 PersistentVolumeClaim（PVC）都可以使用的字段，用来 关联 PV 与 StorageClass，或指定 PVC 想要使用哪个存储类。|
|volumeAttributesClassName|\<string>|用于为使用 CSI 驱动的 PVC 指定一个 VolumeAttributesClass 对象，进而注入或修改卷的挂载属性（volume attributes/mount options）——而不是直接由 StorageClass 或 PV 固定写死。|
|volumeMode|\<string>| PersistentVolume（PV）和 PersistentVolumeClaim（PVC）里用来定义 卷的访问方式类型的字段，指定底层存储是以传统文件系统形式挂载，还是以块设备形式挂载。|

## PVC

PVC（PersistentVolumeClaim，持久卷声明）是用户向集群申请存储资源的对象。它是对存储需求的声明，而不是具体的存储实现，实际的存储由 PV（PersistentVolume，持久卷）来提供。

工作流程：

1. 用户创建PVC
用户在Pod或其他资源中声明需要多少存储空间、访问模式（ReadWriteOnce、ReadOnlyMany、ReadWriteMany）等。

2. PVC与PV匹配
Kubernetes控制器负责查找已有的PV，匹配满足PVC请求的PV。如果有符合条件的未绑定PV，自动绑定。

3. 动态供应（如果没有合适PV）
如果PVC指定了StorageClass，且没有合适的PV，系统会触发动态供应机制，调用对应的存储插件动态创建一个PV。

4. 绑定（Binding）
PV被绑定给PVC后，该PVC状态变为“Bound”，PVC就可以被Pod挂载使用。

5. 挂载使用
Pod声明使用PVC后，Kubelet会根据PVC绑定的PV挂载相应的存储卷。

|字段|类型|描述|
|----|---|----|
|apiVersion|\<string>|Kubernetes API 版本，值为：`v1`|
|kind|\<string>|资源类型，值为：`PersistentVolumeClaim`|
|metadata|\<ObjectMeta>|该资源元数据，[参考Metadata](/kubernetes/PodFeilds.md#metadata)|
|spec|\<PersistentVolumeClaimSpec>|PVC 的详细规格，是最核心的部分。|
|status|\<PersistentVolumeClaimStatus>|描述当前 PV 的状态，系统填充/只读|

### pvc.spec

|字段|类型|描述|
|----|----|----|
|accessModes|\<[]string>|用来声明Pod对存储卷的访问权限和方式。这个字段决定了挂载存储时，卷可以被多少个节点以及以什么读写权限使用。要和PV声明的`accessModes`匹配，否则将绑定失败|
|dataSource|\<TypedLocalObjectReference>|允许你基于已有的存储资源创建新的PVC，PVC克隆、VolumeSnapshot恢复|
|dataSourceRef|\<TypedObjectReference>|作为 dataSource 的增强和替代，用来引用PVC的数据源（比如PVC克隆、快照恢复等），它提供了更灵活和安全的引用方式。|
|resources|\<VolumeResourceRequirements>| PVC（PersistentVolumeClaim）和 Pod 等资源规格中用于声明资源请求和限制的字段，最常用的是 requests，表示希望分配的资源大小。|
|selector|\<LabelSelector>|用来通过标签选择器（Label Selector）筛选满足条件的 PersistentVolume（PV），从而实现更精准的PV绑定。|
|storageClassName|\<string>|用来指定该PVC要绑定的 StorageClass，也就是存储的“类别”或“策略”。|
|volumeMode|\<string>|用来指定申请的存储卷的访问模式——是以块设备（Block）形式还是文件系统（Filesystem）形式挂载到Pod中。对应的 PersistentVolume (PV) 也必须设置相同的 volumeMode，否则无法绑定。|
|volumeName|\<string>|用于指定PVC绑定的具体 PersistentVolume (PV) 名称。|