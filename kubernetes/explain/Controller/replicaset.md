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

ReplicaSet 的存在不是为了直接让用户频繁操作，而是作为 Kubernetes 控制器架构的基石，专门负责保证Pod副本数的“生命线”工作。

换句话说：

它是 Kubernetes 里确保Pod数量和运行状态的“守护者”，

也是 Deployment 和其他更复杂控制器的“核心引擎”。

这就是为什么你在实际工作中，通常不会单独用 ReplicaSet 直接部署应用，而是用它背后的 Deployment 代替。ReplicaSet 的职责就是保证你期望的Pod数在任何时刻都存在。
这是 Kubernetes 做到自愈和弹性伸缩的根基。