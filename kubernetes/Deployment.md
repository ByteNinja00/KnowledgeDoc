# Deployment

Deployment 是 Kubernetes（或类似容器编排系统）中一个非常核心的概念，理解它对运维工程师来说是必须的。

实话实说，Deployment 就是用来管理应用的“声明式升级与回滚”的控制器。

## 主要功能

- **滚动升级（Rolling Update）**
Deployment支持平滑升级，逐步替换旧版本Pod，保证应用无缝升级，避免停机。

- **回滚（Rollback）**
如果升级出问题，可以快速回滚到之前稳定的版本。

- **扩缩容（Scaling）**
通过修改副本数，Deployment可以自动调整Pod数量。

- **自愈（Self-healing）**
Pod挂掉了，Deployment会自动重新创建，保证副本数稳定。

## 工作原理

**1. 你写一个 Deployment YAML 文件，里面定义镜像版本、资源要求、副本数等。**

**2. 通过 kubectl apply -f deployment.yaml 提交给 Kubernetes。**

**3. Kubernetes根据这个定义创建 ReplicaSet，ReplicaSet负责具体的Pod副本管理。**

**4. Deployment管理ReplicaSet，控制版本升级和回滚。**

Deployment 就是 Kubernetes 里声明式管理应用生命周期的关键资源，帮助实现自动化、可控的应用发布与维护。

## 字段

```yaml
apiVersion: <string>
kind: <string>
metadata: <ObjectMeta>
spec: <DeploymentSpec>
status: <DeploymentStatus>
```

### metadata

[参考metadata](/kubernetes/PodFeilds.md)

### spec

|字段             |类型     |描述                                                                                      |
|----------------|---------|------------------------------------------------------------------------------------------|
|minReadySeconds|\<integer>|Pod 在就绪（Ready）状态后，必须持续保持该状态的最短时间（秒），才会被视为“可用（Available）”副本。|
|paused|\<boolean>|它的作用是暂停 Deployment 的变更行为，让你可以更安全地观察或分步调整。|
|progressDeadlineSeconds|\<integer>|用于控制 Deployment 的最大容忍“无进展”时间，帮助你及时发现部署失败或卡死的情况。|
|replicas|\<integer>|指定希望运行的 Pod 副本数量。|
|revisionHistoryLimit|\<integer>|用于控制历史版本保留数量的重要字段。它直接关系到你能不能快速回滚，以及集群的资源占用。|
|selector|\<LabelSelector>|LabelSelector 就是定义匹配哪些标签的语法规则。|
|strategy|\<DeploymentStrategy>|如何进行 Pod 升级（滚动更新）的策略配置。它定义了部署过程中新旧 Pod 的切换方式，比如是渐进式替换，还是先全部删光再重建。|
|template|\<PodTemplateSpec>|定义 Pod 模板的核心字段|

#### selector

匹配标签规则。

- **matchExpressions**

```yaml
spec:
  selector:
    matchExpressions:
      - key: app
        operator: In
        values: ["nginx", "apache"]
      - key: env
        operator: NotIn
        values: ["dev"]
```

- **matchLabels**

```yaml
spec:
  selector:
    matchLabels:
      app: nginx
      tier: frontend
```

#### strategy

