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
|[configMap](/kubernetes/data-persistence.md#configmap)|\<ConfigMapVolumeSource>|用于将一个 ConfigMap 中的数据以文件的形式挂载到容器中。适用于将配置信息从 ConfigMap 注入容器，比如配置文件、启动参数等。|
|[csi](/kubernetes/data-persistence.md#csi)|\<CSIVolumeSource>|用于连接各种第三方或云平台的存储系统。|
|[downwardAPI](/kubernetes/data-persistence.md#downwardapi)|\<DownwardAPIVolumeSource>|用来将 Pod 的元数据信息（如标签、名称、资源限制等） 以文件的形式挂载进容器。这使得容器可以感知自身的运行信息，不需要通过 API Server 访问。|
|[emptyDir](/kubernetes/data-persistence.md#emptydir)|\<EmptyDirVolumeSource>|定义的一种临时存储卷类型。在 Pod 生命周期内共享存储用得最多的就是它，尤其是在容器之间需要共享临时文件时。|
|[ephemeral](/kubernetes/data-persistence.md#ephemeral)|\<EphemeralVolumeSource>|主要是为了支持 轻量级、临时的卷生命周期管理，本质上是一个对 EmptyDir、ConfigMap、Secret 等临时存储资源的抽象封装，符合 Pod 生命周期。|

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