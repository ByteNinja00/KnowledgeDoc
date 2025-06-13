# 容器探针

容器探针（Container Probes）主要用于容器编排系统（尤其是 Kubernetes）中，用来检测容器的运行状态和健康状况，从而保障应用的高可用和稳定运行。

## 一、 Liveness Probe（存活探针）

- 作用：判断容器是否存活。如果探针失败，Kubernetes 会杀掉这个容器并重启它。
- 场景：容器进程进入死锁、卡死或异常状态但还没崩溃时，Liveness 探针能发现并触发重启。

|字段|类型|描述|
|----|----|----|
|exec|`<ExecAction>`|在容器内指定命令探测|
|failureThreshold|`<integer>`|连续失败多少次后，才认为探针真正失败。默认：3|
|grpc|`<GRPCAction>`|基于grpc的健康检查，gRPC 是基于 HTTP/2 的协议，探针不能像普通 HTTP GET 那样简单用 URL 检测。|
|httpGet|`<HTTPGetAction>`|HTTP请求|
|initialDelaySeconds|`<integer>`|容器启动后，等多少秒后开始执行探针检测。|
|periodSeconds|`<integer>`|容器启动后（经过 initialDelaySeconds），探针每隔多少秒执行一次健康检查。默认：10s|
|successThreshold|`<integer>`|容器探针检测时，连续成功多少次，才认为容器“变为健康”或“准备好提供服务”。只对 Readiness Probe 和 Startup Probe 有效，默认：1s|
|tcpSocket|`<TCPSocketAction>`|基于TCP协议探测|
|terminationGracePeriodSeconds|`<integer>`|给容器的“宽限时间”（秒数），容器有这段时间来完成清理和优雅退出。如设置将覆盖Pod设置的值。|
|timeoutSeconds|`<integer>`|探测超时设置，默认：1s|

## 二、Readiness Probe（就绪探针）

- 作用：判断容器是否准备好对外提供服务。如果探针失败，容器不会被加入到服务负载均衡中。
- 场景：容器刚启动，或后端依赖尚未准备好，不希望流量打到此容器时使用。

[字段参考](/kubernetes/explain/containersProbe.md#一-liveness-probe存活探针)

## 三、Startup Probe（启动探针）

- 作用：专门用来判断容器启动过程是否正常。启动探针失败会重启容器，但在启动探针成功之前，Liveness 探针不会起作用。
- 场景：应用启动时间很长，避免启动期间被 Liveness 误判。

[字段参考](/kubernetes/explain/containersProbe.md#一-liveness-probe存活探针)

### ExecAction

- command       `<[]string>`

```bash
exec:
  command:
  - /bin/bash
  - cat /tmp/healthy
```

### GRPCAction

- port  `<integer> -required-`
  gRPC 服务监听的端口号，可以是端口名或端口号。
- service
  gRPC 健康检查中的 service 名称，可以为空（""） 表示检测整个 gRPC 服务。

```bash
grpc:
  port: 50051
  service: my.grpc.HealthCheckService
```

> [!NOTE]
> 使用前提
>
> - 容器内必须实现并注册了标准的 gRPC Health 服务（grpc.health.v1.Health）。
> - 使用的 Kubernetes 版本必须是 v1.24+
> - 必须开启 GRPCContainerProbe feature gate（v1.24 默认开启，v1.27 GA，无需开启）。
> - gRPC 服务监听的是容器内的端口。

### HTTPGetAction

- host `<string>` : 要连接的主机名。

- httpHeaders `<[]HTTPHeader>`
  - name: 请求头的名称，必须是合法的 HTTP Header 名称。
  - value: 请求头的值。

- path: `<string>` HTTP请求的路径。

- port: `<IntOrString> -required-` 端口号。

- scheme: `<string>` 请求HTTP协议的模式。
  枚举值：
  - HTTP
  - HTTPS