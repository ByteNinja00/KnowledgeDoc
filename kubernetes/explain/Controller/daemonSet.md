# DaemonSet

DaemonSet是Kubernetes中的一种控制器（Controller），它确保在集群的每个（或者符合条件的）节点上运行一个指定的Pod副本。换句话说，DaemonSet负责“节点级别”的Pod部署，而不是像Deployment那样按需求自动伸缩。

## 典型应用场景

- 日志收集：比如Fluentd、Filebeat，必须在每台节点上运行，收集本地日志。

- 监控采集：Prometheus Node Exporter、Datadog agent等。

- 网络插件：Calico、Weave等网络方案需要在每个节点上部署代理或服务。

- 安全扫描：运行安全Agent监控节点行为。

## 字段结构

|字段      |类型         |描述       |
|:---------|:-----------|:----------|
|`apiVersion`|`<string>`|值：apps/v1|
|`kind`|`<string>`|DaemonSet|
|`metadata`|`<ObjectMeta>`|[metadata](/kubernetes/explain/Pod.md#metadata)|
|`spec`|`<DaemonSetSpec>`|DaemonSet控制器规格|
|`status`|`<DaemonSetStatus>`|最近运行的状态|

### DaemonSetSpec

它指定了 DaemonSet 应该如何运行 Pod，包括哪些节点运行，运行什么内容，更新策略等。

|字段             |类型  |描述 |
|:----------------|:----|:----|
|minReadySeconds|`<integer>`|Pod启动并就绪后，等待多少秒才算真的可用，避免因为Pod频繁重启导致的更新失败。|
|revisionHistoryLimit|`<integer>`|保留的历史Pod模板版本数，方便回滚。|
|[selector](/kubernetes/explain/Controller/daemonSet-spec.md#dsspecselector)|`<LabelSelector> -required-`|必填字段，标签选择器，用来匹配Pod。DaemonSet通过它管理Pod。必须和template.metadata.labels匹配，否则会报错。|
|[template](/kubernetes/explain/Controller/daemonSet-spec.md#dsspectemplate)|`<PodTemplateSpec> -required-`|定义每个节点上Pod的样子，类似Deployment的Pod模板，里面写容器镜像、端口、资源限制、环境变量等。|
|[updateStrategy](/kubernetes/explain/Controller/daemonSet-spec.md#dsspecupdatestrategy)|`<DaemonSetUpdateStrategy>`|决定DaemonSet更新Pod的方式|
