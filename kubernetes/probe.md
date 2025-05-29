# 容器探针

Kubernetes 中的容器探针（Probe）用于检测容器的 运行状态 和 服务可用性，是容器生命周期管理和服务稳定性保障的关键机制。

探针分为三种类型：

1. Liveness Probe（存活探针）
2. Readiness Probe（就绪探针）
3. Startup Probe（启动探针）

## Liveness Probe（存活探针）

作用：判断容器是否“活着”，即是否需要重启。

失败处理：探测失败会导致容器被 kubelet 杀掉，并根据 restartPolicy 重启。

常用场景：应用发生死锁、不响应请求但进程未退出。

## Readiness Probe（就绪探针）

作用：判断容器是否准备好接收请求。

失败处理：探测失败时，Pod 会从 Service 的 Endpoint 中移除，不再接收流量，但容器不会被重启。

常用场景：程序启动时间长、需连接数据库等资源准备完毕。

## Startup Probe（启动探针）

作用：判断容器启动是否完成，用于替代 Liveness 探针在启动阶段的探测行为。

常用场景：启动时间较长的应用。启动成功后，才启用 Liveness Probe。

### 字段解析

|字段|类型|描述|
|----|-----|-----|
|exec|ExecAction|执行命令探测。|
|failureThreshold|integer|失败阈值，连续失败几次才认为容器不健康。默认 3|
|grpc|GRPCAction|GRPC 指定 GRPC HealthCheckRequest|
|httpGet|HTTPGetAction|使用 HTTP 请求方式探测。|
|initialDelaySeconds|integer|容器启动后，等待多少秒开始第一次探测。默认 0|
|periodSeconds|integer|探测的频率，单位秒。默认 10|
|successThreshold|integer|成功阈值，连续成功几次才认为探测成功。通常为 1（liveness 固定为 1）|
|tcpSocket|TCPSocketAction|通过 TCP 端口建立连接探测。|
|terminationGracePeriodSeconds|integer|表示探测失败后 Pod 需要优雅终止的时间。|
|timeoutSeconds|integer|探测超时时间，单位秒。默认 1|

### 示例

- httpGet

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
    scheme: HTTP       # 或 HTTPS
    httpHeaders:       # 可选，自定义 header
      - name: Custom-Header
        value: Awesome
```

- tcpSocket：

```yaml
livenessProbe:
  tcpSocket:
    port: 3306
```

- exec：

```yaml
livenessProbe:
  exec:
    command:
      - cat
      - /tmp/healthy
```

### 示例组合配置

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 2
  failureThreshold: 3
```