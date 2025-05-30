# ReplicaSet

ReplicaSet 是 Kubernetes 中的一种控制器（Controller），其主要作用是保证某个 Pod 的副本数量始终维持在用户所定义的期望值。简单来说，它确保在任何时候，都有指定数量的 Pod 副本在集群中运行。

> [!WARNING]
>
> 1. 不要直接使用 ReplicaSet 来部署应用。官方推荐使用 Deployment 控制器，它内部其实就是管理 ReplicaSet。
> 2. 如果 selector 和 template.metadata.labels 不匹配，ReplicaSet 不会创建任何 Pod。
> 3. ReplicaSet 不会自动更新已有 Pod，修改镜像不会触发滚动更新——这就是为什么一般使用 Deployment 而不是直接用 ReplicaSet。

## 对比Deployment

| 功能     | ReplicaSet | Deployment |
| ------ | ---------- | ---------- |
| 管理副本   | ✅          | ✅          |
| 自动滚动更新 | ❌          | ✅          |
| 回滚历史版本 | ❌          | ✅          |

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: my-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
```

