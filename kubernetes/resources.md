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

- apiversion:
APIVersion 定义了此对象表示的版本化架构。服务器应将已识别的架构转换为最新的内部值，并且可能会拒绝无法识别的值。
要查看有apiversion哪些受支持：

```bash
kubectl api-version
```

- kind:
Kind 是一个字符串值，表示此对象所代表的 REST 资源。服务器可以根据客户端提交请求的端点推断出此值。无法更新。采用驼峰命名法。
查看kind资源类型：

```bash
kubectl api-resources
```

- metadata
标准对象的元数据。[参考metadata下字段](/kubernetes/metadata.md)

- spec
指定 Pod 的期望行为。

- status
Pod 的最新状态。此数据可能不是最新的。由系统填充。只读。