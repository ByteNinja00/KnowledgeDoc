# 容器相关字段

pod.spec.containers 是定义 Pod 内一个或多个容器（Containers） 的核心字段。它是一个数组，每一项代表一个容器的配置。

## 字段

|  字段 |        类型        |                                         说明                                                      |
|:------|:------------------|:--------------------------------------------------------------------------------------------------|
|args|`<[]string>`|替换掉镜像默认的 CMD。|
|command|`<[]string>`|替换掉镜像默认的 ENTRYPOINT|
|env|`<[]EnvVar>`|环境变量设置（支持从 ConfigMap、Secret 引用）|
|envFrom|`<[]EnvFromSource>`|是 container 下用于批量导入环境变量的字段，常用于从 ConfigMap 或 Secret 中一次性加载多个键值对为环境变量。|

