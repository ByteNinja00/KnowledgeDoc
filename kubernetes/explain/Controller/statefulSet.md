# statefulSet

StatefulSet 是一种用于管理有状态应用的控制器。与 Deployment 不同，它专门为那些每个副本需要有稳定标识符、稳定存储、稳定网络标识以及有序部署和删除顺序的服务而设计。

## 特点

| 特性         | 说明                                                               |
| ---------- | ---------------------------------------------------------------- |
| 稳定的 Pod 名称 | 每个 Pod 都会有固定名称，如 `web-0`、`web-1`                                 |
| 稳定的存储      | 每个 Pod 绑定自己的 PVC，不会与其他 Pod 共享                                    |
| 有序部署和删除    | Pod 是按顺序创建/删除的，确保服务启动顺序和依赖关系                                     |
| DNS 名称稳定   | 每个 Pod 的 DNS 是固定的，如 `web-0.svc-name.namespace.svc.cluster.local` |

## 字段结构

|字段|类型|描述|
|---|----|----|
|apiVersion|\<string>|值：apps/v1|
|kind|\<string>|值：StatefulSet|
|metadata|\<ObjectMeta>|[metadata](/kubernetes/explain/Pod.md#metadata)|
|spec|\<StatefulSetSpec>|Spec 定义了该集合中 pod 的所需身份。|
|status|\<StatefulSetStatus>|描述该statefulset近期状态，系统填充/只读|

### StatefulSetSpec

