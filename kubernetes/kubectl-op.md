# kubectl高频操作命令

日常kubernetes运维中经常用到的kubectl命令。

## API相关

- 查看支持的API资源版本：

```bash
kubectl api-versions
```

- 查看支持的API资源:

```bash
kubectl api-resources
```

## 辅助

kubectl 命令不算多，但是子命令和参数是很多的，如果不知道如何使用可以使用 `explain`。

- 查看Deployment控制器下有哪些字段:

```bash
kubectl explain deployment
```

- 进一步查看该字段下的子字段：

```bash
kubectl explain deployment.spec
```

## 集群级别

- 获取集群资源列表:

```bash
kubectl get ns
```

> [!TIP]
> `ns`代表命名空间资源。

- 查看集群资源列表:

```bash
kubectl describe ns kube-node-lease
```

> [!TIP]
> `kube-node-lease` 在 ns 命名空间下的对象名称。

### Pod

集群下kubectl操作Pod资源对象。

- 获取一个命名空间下的pod:

```bash
kubectl get pod -n kube-system
```

- 查看命名空间下的Pod详细描述：

```bash
kubectl describe pod -n default podName
```

- 删除Pod（对于自主管理Pod慎用）:

```bash
kubect delete pod -n default podName
```

- 创建Pod：

```bash
kubectl apply -f pod.yaml
```

> [!NOTE]
> 官方建议使用声明式创建Pod

