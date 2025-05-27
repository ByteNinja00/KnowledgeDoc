# 资源对象字段

在管理Kubernetes资源对象时，kubectl命令可以打印出支持的资源对象字段。

```bash
kubectl explain resources
```

> [!NOTE]
> 上述命令中resources为需要说明的字段。

如果需要更进一步查看当前资源对象下的子对象说明，以Pod资源对象为例：

```bash
kubectl explain Pod.metadata
```

## Pod资源对象

Pod 是可在主机上运行的容器的集合。此资源由客户端创建并调度到主机上。

层级结构：

``` yaml
apiVersion: string
kind: string
metadata: ObjectMeta
spec: PodSpec
status: PodStatus
```

