# 容器相关字段

pod.spec.containers 是定义 Pod 内一个或多个容器（Containers） 的核心字段。它是一个数组，每一项代表一个容器的配置。

## 字段

|  字段 |        类型        |                                         说明                                                      |
|:------|:------------------|:--------------------------------------------------------------------------------------------------|
|args|`<[]string>`|替换掉镜像默认的 CMD。|
|command|`<[]string>`|替换掉镜像默认的 ENTRYPOINT|
|env|`<[]EnvVar>`|环境变量设置（支持从 ConfigMap、Secret 引用）|
|envFrom|`<[]EnvFromSource>`|是 container 下用于批量导入环境变量的字段，常用于从 ConfigMap 或 Secret 中一次性加载多个键值对为环境变量。|
|image|`<string>`|指定容器运行的镜像|
|imagePullPolicy|`<string>`|镜像拉取策略：`Always`, `IfNotPresent`,`Never`|
|lifecycle|`<Lifecycle>`|允许你在容器的生命周期中特定的时刻（例如启动或终止时）执行特定的操作，比如运行脚本或调用 HTTP 接口。|
|[livenessProbe](/kubernetes/explain/containersProbe.md#一-liveness-probe存活探针)|`<Probe>`|容器存活探针，检查容器是否正常服务。|
|name|`<string> -required-`|为容器命名|
|ports|`<[]ContainerPort>`|ports 字段用于声明容器对外暴露的端口。只是声明并不会实际开放端口，需要通过service给外部访问|
|[readinessProbe](/kubernetes/explain/containersProbe.md#二readiness-probe就绪探针)|`<Probe>`|就绪探针，判断容器是否就绪提供服务|
|resizePolicy|`<[]ContainerResizePolicy>`|容器资源重新调整策略|
|resources|`<ResourceRequirements>`|用于声明 容器对计算资源的需求和限制|
|restartPolicy|`<string>`|RestartPolicy 定义了 Pod 中各个容器的重启行为。此字段只能为 Init 容器设置，并且唯一允许的值为“Always”。对于非 Init 容器或未指定此字段的情况，重启行为由 Pod 的重启策略和容器类型定义。|
|securityContext|`<SecurityContext>`|用于定义 Pod 或容器的安全相关配置，如用户权限、文件系统访问控制、能力限制、SELinux/AppArmor 设置等。|
|[startupProbe](/kubernetes/explain/containersProbe.md#三startup-probe启动探针)|`<Probe>`|用于检测容器 启动是否完成，尤其适用于启动时间较长的服务（例如 Java 应用、数据库等）。|
|stdin|`<boolean>`|用于指定容器是否要分配一个 标准输入（stdin）流，常用于 交互式容器场景，例如调试用的 kubectl exec 或 kubectl attach。|
|stdinOnce|`<boolean>`|用于控制 标准输入（stdin）流的生命周期。它通常和 stdin: true 一起使用，用于控制是否只允许一次标准输入连接。|
|terminationMessagePath|`<string>`|用来指定 容器终止时，读取终止信息的文件路径。这个文件的内容会被 Kubernetes 读取，并作为容器终止原因（termination message）存储在 Pod 状态中，方便调试和排查问题。|
|tty|`<boolean>`|用于指定是否为容器分配一个伪终端（pseudo-TTY）。|
|volumeDevices|`<[]VolumeDevice>`|用于 将块设备（block device）直接挂载到容器中。|
|volumeMounts|`<[]VolumeMount>`|用于将 Pod 级别定义的卷（volume）挂载到容器内的指定路径，让容器可以访问该卷中的数据。|
|workingDir|`<string>`|指定容器当前的工作目录|