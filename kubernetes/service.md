# Service

Kubernetes 中的 Service（服务）是一种抽象定义，用于暴露一组 Pod 的网络访问能力。它实现了 Kubernetes 中的服务发现和负载均衡功能。

## 功能

1. 稳定的访问入口
Pod 会频繁重建（IP 会变），Service 提供一个稳定的虚拟 IP（ClusterIP），供客户端使用。

2. 负载均衡
同一个 Service 后端可能对应多个 Pod，访问 Service 时，Kubernetes 会将请求负载均衡地转发到后端 Pod。

3. 服务发现
其他 Pod 可以通过 DNS 名称（如 my-service.my-namespace.svc.cluster.local）发现并访问这个 Service。

## 字段

|字段|类型|描述|
|----|----|----|
|apiVersion|\<string>|值：v1|
|kind|\<string>|值：Service|
|metadata|\<ObjectMeta>|资源的数据描述[参考metadata](/kubernetes/PodFeilds.md#metadata)|
|spec|\<ServiceSpec>|资源对象期望行为描述|
|status|\<ServiceStatus>|只读，由系统生成|

### Spec

Spec 定义了服务的行为。

#### - allocateLoadBalancerNodePorts