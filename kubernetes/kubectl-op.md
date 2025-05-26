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

- 获取xx命名空间下的Pod:

```bash
kubectl get pods -n kube-system
```

> [!TIP]
> `-n kube-system` 为指定的命名空间

- 获取集群资源列表:

```bash
kubectl get ns
```

> [!TIP]
> `ns`代表命名空间资源。