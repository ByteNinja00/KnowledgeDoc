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