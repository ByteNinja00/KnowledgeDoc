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

