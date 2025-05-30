# Containers

用于描述 Pod 中运行的一个或多个容器的详细配置。

字段列表：

|字段|类型|描述|
|----|----|----|
|args| []string|传递给 command 的参数|
|command| \[]string| 容器启动时的命令（替代镜像默认 CMD）|
|env| \[]EnvVar| 环境变量设置|
|envFrom| \[]EnvFromSource|ll|
|image|string|使用的容器镜像，例如 nginx:1.21|
|imagePullPolicy|string|镜像拉取策略（Always、IfNotPresent 等）|
|lifecycle|Lifecycle|ll|
|livenessProbe|Probe|容器存活探测|
|name|string|容器名称|
|ports|\[]ContainerPort|容器暴露的端口（如 HTTP 端口等）|
|readinessProbe|Probe|容器就绪探测|
|resizePolicy|\[]ContainerResizePolicy|ll|
|resources|ResourceRequirements|ll|
|restartPolicy|string|容器重启策略|