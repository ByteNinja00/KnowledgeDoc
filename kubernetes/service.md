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
|externalTrafficPolicy|\<string>|用于控制 外部访问流量如何在 Node 上分发 的一个关键字段，仅适用于 type: NodePort 或 LoadBalancer 的 Service。值：Cluster（默认）和 Local|
|healthCheckNodePort|\<integer>|仅在 Service.type: LoadBalancer 且 externalTrafficPolicy: Local 时可用，用于配合 云负载均衡器（如 AWS ELB、GCP LB、阿里云 SLB） 对集群节点进行 健康检查。|
|internalTrafficPolicy|\<string>|用于控制 集群内访问 Service 时的流量调度策略，即 来自集群内部的流量（非外部访问）应该如何选择后端 Pod。|
|ipFamilies|\<[]string>|用于指定 Service 支持的 IP 地址族类型（IP Family），即决定 Service 可用的是 IPv4、IPv6 还是双栈（双协议栈）模式。|
|ipFamilyPolicy|\<string>|用来控制 Service 分配 IP 地址族策略的字段。它决定了该 Service 支持的 IP 地址族类型以及如何分配单栈还是双栈 IP。|
|loadBalancerSourceRanges|\<[]string>|定义一组 IP 地址 CIDR 列表，只有这些范围内的客户端 IP 能够通过云负载均衡器访问对应的 Service。其他 IP 会被拒绝。|
|ports |\<[]ServicePort>|指定svc端口列表，用于定义该 Service 对外暴露的端口映射关系。|
|publishNotReadyAddresses|\<boolean>|如果将 publishNotReadyAddresses: true，那么即使 Pod 还没有 Ready（比如启动中或刚加入集群未就绪），它们的 IP 也会被加入 Endpoints，Service 会同时包含这些“不健康” Pod。|
|selector|<map[string]string>|Kubernetes 会选中所有匹配这些标签的 Pod，将它们的 IP 和端口添加到 Service 的 Endpoints 中。|
|sessionAffinity|\<string>|用来控制会话亲和性的字段，决定客户端请求是否总是“黏”到同一个后端 Pod。|
|type|\<string>|用于指定 Service 对外暴露的方式，决定服务如何被访问及其网络行为。|

#### allocateLoadBalancerNodePorts

- 默认情况下，type: LoadBalancer 的 Service 会自动为每个端口分配一个 nodePort，允许节点端口访问流量直接转发到 Service。
- 如果将 allocateLoadBalancerNodePorts: false，则不会分配 nodePort，节点端口不可用，只能通过 LoadBalancer IP 访问。
- 适用于某些场景下不想开放节点端口，只通过负载均衡器访问 Service。

```yaml
apiVersion: v1
kind: Service
metadata: 
    name: loadblacer-service
spec:
    type: LoadBalancer
    allocateLoadBalancerNodePorts: false
    selector:
        podlabel: my-pod-label
    ports:
        - port: 80
          targetPort: 8080
```

#### externalName

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-external
spec:
  type: ExternalName
  externalName: db.example.com
```

此时应用可以用 mysql-external.default.svc.cluster.local 来连接 db.example.com 上的 MySQL，避免硬编码外部域名。

#### externalTrafficPolicy	

可选值：

| 值         | 含义                                            |
| --------- | --------------------------------------------- |
| `Cluster` | 默认值。请求会被 kube-proxy 负载均衡到任意 Pod，**可能丢失源 IP**。 |
| `Local`   | 只转发到当前节点上有对应 Pod 的流量，**保留源 IP**。              |

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  externalTrafficPolicy: Local
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

外部访问 \<NodeIP>:30080 时：

- 若 externalTrafficPolicy: Cluster，请求可能被转发到其他节点上的 Pod，源 IP 会被 NAT 掉（看到的是节点 IP）。

- 若 externalTrafficPolicy: Local，只有该节点本地存在匹配的 Pod，才会处理请求，源 IP 保留，利于日志分析或基于 IP 的访问控制。