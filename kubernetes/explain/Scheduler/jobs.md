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
