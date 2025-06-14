# Deployment控制器

在 Kubernetes 中，Deployment 是一种 控制器（Controller），用于声明式地管理一组 Pod 副本（Replica） 的部署和生命周期。它封装了创建和更新 Pod 和 ReplicaSet 的逻辑。

## 核心功能

Deployment 的主要功能是：

- 定义应用的期望状态（例如运行几个副本、使用什么镜像）

- 自动化滚动更新（Rolling Update） 和 回滚（Rollback）

- 保证副本数量（自动重建因故障退出的 Pod）

- 统一升级策略和版本控制

Deployment 是 Kubernetes 中最常用的工作负载资源之一，适用于大多数 无状态服务 场景。它提供了自动化部署、更新、回滚和副本管理，是运维和开发之间的桥梁。

## 字段结构

|字段|类型|描述|
|:---|:---|:---|
|apiVersion|`<string>` |值：`apps/v1` |
|kind|`<string>` |值：`Deployment` |
|metadata |`<ObjectMeta>`|参考[metadta](/kubernetes/explain/Pod.md#metadata)|
|spec|`<DeploymentSpec>`|Deployment规格|
|status|`<DeploymentStatus>`|最近Deployment的状态 |

### DeploymentSpec

它定义了该`Deployment`的期望状态。换句话说，它告诉 Kubernetes：我要部署什么、部署多少个、怎么部署、怎么更新。

|      字段     |         类型       |                                             描述                                                 |
|:--------------|:------------------|:-------------------------------------------------------------------------------------------------|
|minReadySeconds|`<integer>`|每个新 Pod 启动并变成 Ready 后，Kubernetes 还要观察 10 秒，确认它没有立刻挂掉或者崩溃，才算这个 Pod 是 “可用的”。|
|paused|`<boolean>`|表示是否暂停（pause）Deployment 的滚动更新行为。|
|progressDeadlineSeconds|`<integer>`|用来控制滚动更新的超时时间。|
|replicas|`<integer>`|Pod副本数。|
|revisionHistoryLimit|`<integer>`|保留多少个历史版本。|
|selector|`<LabelSelector> -required-`|标签选择器对应Pod中的label。|
|strategy|`<DeploymentStrategy>`|滚动更新策略。|
|template|`<PodTemplateSpec> -required-`|定义Pod模板规格|

