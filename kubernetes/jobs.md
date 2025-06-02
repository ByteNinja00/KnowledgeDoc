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

