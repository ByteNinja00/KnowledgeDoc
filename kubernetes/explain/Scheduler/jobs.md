# Jobs控制器

Kubernetes 的 Jobs 控制器（Job Controller） 是用来管理一次性任务的核心组件，它确保一个或多个 Pod 成功结束（完成），适用于 批处理任务、数据处理、初始化工作 等场景。

## 字段结构

|   字段   |   类型    |   描述   |
|:---------|:---------|:---------|
|apiVersion|`<string>`|`batch/v1`|
|kind|`<string>`|Job|
|metadata|`<ObjectMeta>`|[metadata](/kubernetes/explain/Pod.md#metadata)|
|spec|`<JobSpec>`|Jobs任务规格|
|status|`<JobStatus>`|当前Job状态，系统填充/只读|

### jobs.spec

|        字段         |   类型    |   描述   |
|:--------------------|:---------|:---------|
|activeDeadlineSeconds|`<integer>`|用于限制 整个 Job 的最长运行时间。一旦超时，不管 Job 是否完成，Kubernetes 都会终止它，并将 Job 标记为失败。|
|backoffLimit|`<integer>`|用于控制 Pod 失败后的最大重试次数。默认：6|
|backoffLimitPerIndex|`<integer>`|用于控制 "并行带索引（Indexed Job）" 中每个索引 Pod 的最大重试次数，是对 backoffLimit 的一个更精细化的增强。|
|completionMode|`<string>`|用来控制 Job 的完成判定逻辑。|
|completions|`<integer>`|这个 Job 要有多少个 Pod 成功退出（exit code 0），才算这个 Job 成功完成。|
|managedBy|`<string>`|标明哪个控制器在管理该Job，默认由 Kubernetes 的 Job 控制器进行管理（即经典 Job 控制器会负责同步此 Job）|
|manualSelector|`<boolean>`|用于控制 Job 是否手动管理其 Pod 的选择器。默认情况下控制器会自动创建一个独一无二的 Pod 标签选择器（selector）来匹配由该 Job 创建的 Pod。默认：false|
|maxFailedIndexes|`<integer>`|专门用于配合 completionMode: "Indexed" 的 Job。就是 Job 容忍多少个“索引任务”失败而不算整体 Job 失败。|
|parallelism|`<integer>`|用来控制同时运行的 Pod 实例数。|
|podFailurePolicy|`<PodFailurePolicy>`|允许你根据失败原因（失败类型、退出码、信号、容器名等）指定具体动作。|
|podReplacementPolicy|`<string>`|，专门用来控制 Job 在 Pod 失败或异常时是否替换（重新创建）Pod 的策略。|
|selector|`<LabelSelector>`|默认情况：selector 字段由系统自动生成，和 Pod 模板标签保持一致，用户无需手动设置。手动管理：通过设置 spec.manualSelector: true，可以手动指定 selector，但一般不推荐，容易导致标签冲突。|
|successPolicy|`<SuccessPolicy>`|主要用于控制在某些特殊场景下，Job 如何判定“成功”。|
|suspend|`<boolean>`|suspend 是 Kubernetes Job 资源中一个用于控制 Job 暂停与恢复的字段。|
|template|`<PodTemplateSpec> -required-`|定义了 Pod 的模板规范。|
|ttlSecondsAfterFinished|`<integer>`|用来控制 Job 对象在完成（成功或失败）后，保留的时间（秒数），时间到后 Kubernetes 自动删除该 Job 资源。|

#### jobs.spec.completionMode

有效值：

|      值  |                      描述                                  |
|:---------|------------------------------------------------------------|
|NonIndexed|默认模式，按 Pod 成功次数累计，直到达到 spec.completions 为止。|
|Indexed|每个 Pod 有唯一索引（0 到 completions-1），每个索引都必须成功完成一次才算 Job 完成。|

#### jobs.spec.podFailurePolicy

