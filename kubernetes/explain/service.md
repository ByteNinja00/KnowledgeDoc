# Service

Kubernetes 中的 Service（服务）是一种抽象定义，用于暴露一组 Pod 的网络访问能力。它实现了 Kubernetes 中的服务发现和负载均衡功能。

## 功能

1. 稳定的访问入口
Pod 会频繁重建（IP 会变），Service 提供一个稳定的虚拟 IP（ClusterIP），供客户端使用。

2. 负载均衡
同一个 Service 后端可能对应多个 Pod，访问 Service 时，Kubernetes 会将请求负载均衡地转发到后端 Pod。

3. 服务发现
其他 Pod 可以通过 DNS 名称（如 my-service.my-namespace.svc.cluster.local）发现并访问这个 Service。

## 字段结构

|字段|类型|描述|
|----|----|----|
|apiVersion|\<string>|值：v1|
|kind|\<string>|值：Service|
|metadata|\<ObjectMeta>|资源的数据描述[参考metadata](/kubernetes/PodFeilds.md#metadata)|
|spec|\<ServiceSpec>|资源对象期望行为描述|
|status|\<ServiceStatus>|只读，由系统生成|

### ServiceSpec

spec 是 Service 对象的核心字段，用于定义这个 Service 的具体行为。

**`svc.spec` 的字段和结构:**

|             字段             |    类型   |                                               描述                                      |
|:----------------------------|:----------|:----------------------------------------------------------------------------------------|
|allocateLoadBalancerNodePorts|`<boolean>`|用于控制 LoadBalancer 类型服务是否分配对应的 NodePort。仅适用于 type: LoadBalancer 的 Service|
|clusterIP|`<string>`|手动指定一个静态集群IP，当type: clusterIP时，默认自动分配一个。|
|clusterIPs|`<[]string>`|支持在同一个 Service 中同时配置多个 IP 地址。|
|externalIPs|`<[]string>`|允许你为 Service 配置外部可访问的 IP 地址。这些外部 IP 地址可以直接暴露给外部世界，通常用于让外部系统可以通过特定的 IP 地址访问集群中的 Service。|
|externalName|`<string>`|Kubernetes 只是为外部服务提供一个集群内部的 DNS 名称映射，不会创建实际的服务代理或负载均衡器。|
|externalTrafficPolicy|`<string>`|主要用于控制流量如何进入一个 LoadBalancer 或 NodePort 类型的 Service。|
|healthCheckNodePort|`<integer>`|healthCheckNodePort 是为 外部负载均衡器 提供的一个特定端口，用于健康检查流量。|
|internalTrafficPolicy|`<string>`|，定义了 Service 如何在集群内部路由流量。它主要用于 ClusterIP 类型的 Service，并允许你控制流量是否应该路由到所有的 Pod，还是仅限于部署该 Service 的本地节点上的 Pod。|
|ipFamilies|`<[]string>`|允许你为服务指定支持的 IP 地址族，通常是 IPv4 和 IPv6。|
|ipFamilyPolicy|`<string>`|用于控制 IP 地址族的选择策略，特别是在启用了 双栈（Dual-stack） 网络环境中。|
|loadBalancerClass|`<string>`|选择一个负载均衡器，该负载均衡器在`loadBalancerClass`定义。|
|loadBalancerIP|`<string>`|用于指定 LoadBalancer 类型服务的静态外部 IP 地址。|
|loadBalancerSourceRanges|`<[]string>`|用于限制哪些 源 IP 地址 或 IP 地址段 可以访问 LoadBalancer 类型的服务。|
|[ports](/kubernetes/explain/service.md#specports) |`<[]ServicePort>`|用于定义暴露给外部或其他服务的端口配置。每个 Service 都会通过端口将流量路由到对应的 Pods 中，而 ports 字段是用来指定如何映射这些端口的。|
|publishNotReadyAddresses|`<boolean>`|主要用于控制是否将 NotReady（即处于不健康状态）的 Pods 的 IP 地址发布到服务中。|
|[selector](/kubernetes/explain/service.md#specselector)|`<map[string]string>`|标签选择器，绑定一组Pod能过Labes。|
|[sessionAffinity](/kubernetes/explain/service.md#specsessionaffinity)|`<string>`|允许你指定是否需要将同一个客户端的请求始终路由到相同的 Pod。它的主要作用是在一些需要维持会话状态的应用场景中，例如 Web 应用、数据库连接池、用户身份验证等。|
|[sessionAffinityConfig](/kubernetes/explain/service.md#specsessionaffinityconfig)|`<SessionAffinityConfig>`|用于在启用会话亲和性时提供更细粒度的控制。|
|trafficDistribution|`<string>`|主要用于 负载均衡器类型的服务，帮助你在不同的服务端点之间动态调整流量的分配比例。这对于 灰度发布、Canary 部署 或 蓝绿部署 等场景非常有用，可以根据一定的流量比例逐步引入新版本的服务，确保新版本经过充分的测试后再完全接管流量。|
|type| `<string>`|指定Service的类型。|

#### spec.ports

- appProtocol `<string>` : 应用协议如：http、https、grpc、mysql等。
- name `<string>` : 用于标识端口的名称。
- nodePort `<integer>` : 指定节点端口号。
- port  `<integer> -required- ` : service暴露的端口。
- protocol `<string>` ：端口协议。
  - TCP
  - UDP
  - SCTP
- targetPort `<IntOrString>` : 对应Pod暴露的端口号或名称。

#### spec.selector

```yaml
selector:
    app: nginx
```

#### spec.sessionAffinity

- None（默认）没有会话保持，流量会被随机分发到后端 Pod（轮询负载均衡）
- ClientIP 基于客户端 IP 实现会话保持，同一个客户端 IP 会一直访问同一个 Pod

#### spec.sessionAffinityConfig

- clientIP `<ClientIPConfig>`
  - timeoutSeconds `<integer>` : 设置客户端 IP 会话保持的超时时间，单位为秒。

#### spec.type

- ClusterIP
- ExternalName
- NodePort
