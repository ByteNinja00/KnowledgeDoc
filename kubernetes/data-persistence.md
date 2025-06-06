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

云厂商的存储资源类型己弃用列表:

> [!NOTE]
> 在kubernetes1.32版本中，许多云厂商的存储资源类型己被弃用，改用**CSI(Container Storage Interface)**作为驱动动态挂载任意存储后端（如 rook-ceph、阿里云、AWS EBS 等）。