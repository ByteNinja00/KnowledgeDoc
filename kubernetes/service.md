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

|字段                          |类型      |描述                                                                                                  |
|------------------------------|----------|-----------------------------------------------------------------------------------------------------|
|allocateLoadBalancerNodePorts|\<boolean>|主要在 type: LoadBalancer 类型中使用。它控制的是：当使用 LoadBalancer 类型时，是否分配对应的 NodePort 端口。|
|clusterIP|\<string>|用来指定该 Service 的 虚拟 IP 地址（VIP），它是集群内部通信的核心机制之一。|
|clusterIPs|\<[]string>|用来存放该 Service 的 所有分配的集群内 IP 地址。它用于与 ipFamilies 字段配合，支持双栈（Dual-Stack）Service。|
|externalIPs|\<[]string>|Service 可以被外部 IP 访问，Kubernetes 不管理这些 IP 的路由或归属，只是让 kube-proxy 接收这些 IP 的流量。|
|externalName|\<string>|当你定义一个 type: ExternalName 的 Service，Kubernetes 不会创建集群 IP（没有 clusterIP），也不会进行负载均衡，而是通过 CoreDNS 把 Service 名称直接解析为指定的 外部域名。|
