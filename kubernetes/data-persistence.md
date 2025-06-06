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
|configMap|\<ConfigMapVolumeSource>|用于将一个 ConfigMap 中的数据以文件的形式挂载到容器中。适用于将配置信息从 ConfigMap 注入容器，比如配置文件、启动参数等。|
|csi|\<CSIVolumeSource>|g|

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

