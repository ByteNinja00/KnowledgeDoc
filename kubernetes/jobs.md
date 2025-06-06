# 任务批处理Jobs

Kubernetes 中的 Job 是一种用于一次性任务（batch jobs）的控制器，适用于需要执行一次并成功结束的工作负载，而不是像 Deployment、DaemonSet 那样长期运行的服务型应用。

**它的常见用途包括：**

- 执行数据库迁移脚本

- 执行一次性的数据处理任务

- 清理任务（清除旧文件、日志等）

- 生成报告或备份

## 字段

|字段|类型|描述|
|----|----|----|
|apiVersion|\<string>|batch/v1|
|kind|\<string>|Job|
|metadata|\<ObjectMeta>|[参考metadata](/kubernetes/PodFeilds.md#metadata)|
|spec|\<JobSpec>|期望Job运行的行为|
|status|\<JobStatus>|系统生成|

### Spec

|          字段        |  类型    |                        描述                                                       |
|---------------------|----------|-----------------------------------------------------------------------------------|
|activeDeadlineSeconds|\<integer>|设置 Pod 的生命周期上限，超过这个时间就会被 Kubernetes 强制终止（类似“超时自动取消”机制）|
|backoffLimit|\<integer>|指定将此作业标记为失败之前的重试次数。默认为 6 次|
|backoffLimitPerIndex|\<integer>|指定将索引标记为失败之前，索引内重试的次数限制。|
|completionMode|\<string>|用于指定 Job 的完成策略。从 v1.22 开始正式 GA（通用可用）|
|completions|\<integer>|表示 任务希望成功完成的Pod数。|
|managedBy|\<string>|通常是出现在 资源的元数据标签（labels）里的一个键名，用来标识这个资源是由哪个工具或控制器创建和管理的。|
|manualSelector|\<boolean>|用于控制 Job 是否手动管理其 Selector（Pod 选择器）。|
|maxFailedIndexes|\<integer>|用于控制 Job 在失败任务索引达到指定数量时是否提前失败终止。|
|parallelism|\<integer>|最多允许多少个 Pod 并行同时运行。这是控制并发度的关键参数，适用于所有 Job 模式（普通、Indexed）。|
|podFailurePolicy|\<PodFailurePolicy>|用于定义 Job 在 Pod 失败时如何响应，这是对传统 backoffLimit 的重大增强。|
|podReplacementPolicy|\<string>|用于控制 当 Pod 失败或被驱逐时，Job 是否以及如何替换该 Pod。|
|selector|\<LabelSelector>|用来定义 Pod 的标签选择器（Label Selector），用以关联 Job 管理的 Pod。|
|successPolicy|\<SuccessPolicy>|要用于控制 Job 何时被认为成功，尤其是在并行或索引任务场景下。|
|suspend|\<boolean>|用于控制 暂停/恢复 Job 调度和执行 的一个布尔字段。|
|template|\<PodTemplateSpec>|它定义了 Job 运行的 Pod 模板（PodSpec + PodMetadata）。Job 通过这个模板来创建和管理具体的 Pod。|
|ttlSecondsAfterFinished|\<integer>|用来控制 Job 任务完成（成功或失败）后，该 Job 资源在集群中保留的时间（秒数），时间到后自动被系统清理（删除）。|

#### completionMode

可选值及含义:

|       值          |                 含义                                   |
|-------------------|-------------------------------------------------------|
|NonIndexed（默认）	|普通 Job 的完成模式，Pod 没有索引，完成数由成功 Pod 数累计。|
|Indexed            |Indexed Job 完成模式，每个 Pod 有唯一索引，完成基于所有索引的 Pod 成功。|

#### managedBy

- 默认行为：
Kubernetes Job 会自动为 Pod 创建一个标签选择器（selector），这个选择器与 Pod 模板中的标签（template.metadata.labels）严格匹配，用于识别和管理属于这个 Job 的 Pod。

- manualSelector: true：
如果你设置了 manualSelector: true，Job 不会自动创建选择器和对应标签。
这意味着你必须手动管理 Pod 标签和 Job 选择器，Job 控制器不会自动添加或维护相关标签和选择器。

#### maxFailedIndexes

maxFailedIndexes 是 Kubernetes Indexed Job（即带索引的 Job）中的一个字段，专门用于控制失败索引的容忍度。

定义：允许 Job 中有多少个索引（Index）任务失败而不导致整个 Job 失败。

在 Indexed Job 模式下，如果某些索引对应的 Pod 多次失败，超过这个数量，Job 就会被判定为失败。

默认值：如果不设置，任何索引失败都会导致 Job 失败（即默认是 0）。

#### podFailurePolicy

Jobs.spec.podFailurePolicy.rules:

|规则|描述|
|----|----|
|action|规则匹配时的处理动作，如 FailJob、Ignore、Retry|
|onExitCodes|依据容器退出码来匹配失败|
|onPodConditions|根据 Pod 状态条件匹配失败|

```yaml
podFailurePolicy:
  rules:
  - action: Ignore
    onExitCodes:
      containerName: "worker"
      operator: In
      values: [137]   # OOMKilled 忽略失败
  - action: FailJob
    onPodConditions:
    - type: Ready
      status: False
      reason: NodeLost  # 节点丢失立即失败
  - action: FailJob
    onContainerStatus:
      containerName: "worker"
      state:
        terminated:
          exitCode: 1
          reason: Error  # 退出码1且错误，直接失败
```

#### podReplacementPolicy

- Failed

意味着要等到先前创建的 Pod 完全终止（处于失败或成功阶段）后再创建替换 Pod。

- TerminatingOrFailed

意味着当 pod 终止（具有 metadata.deletionTimestamp）或失败时，我们会重新创建 pod

#### successPolicy

Jobs.spec.successPolicy.rules: 

```yaml
successPolicy:
  rules:
  - action: SucceedJob  # 标记成功
    onExitCodes:
      containerName: "worker"
      operator: In
      values: [0, 143]   # 退出码0和143算成功
  - action: Ignore       # 忽略该 Pod 不计失败也不计成功
    onPodConditions:
      - type: Ready
        status: "False"
        reason: Evicted  # Pod 被驱逐时忽略
```

#### template

[参考template](/kubernetes/DaemonSet.md#template)