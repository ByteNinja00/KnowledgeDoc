# 存储

为集群中的 Pods 提供长期和临时存储的方法。

## Volume(卷)

卷为 Pod 中的容器提供了一种通过文件系统访问和共享数据的方式。
是 Pod 级别的卷（volume）定义，表示 Pod 中容器可挂载的存储资源。它是在 Pod 级别声明的，然后在 container.volumeMounts 中挂载使用。

