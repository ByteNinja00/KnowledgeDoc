# Promethues监控体系

- Prometheus是一个开源系统监控和警报工具包，最初由 SoundCloud构建。
- Prometheus 于 2016 年加入了 云原生计算基金会 ( CNCF)，成为继Kubernetes之后的第二个托管项目。

## 组成结构

Prometheus 生态系统由多个组件组成，其中许多是可选的：

- 抓取并存储时间序列数据的主要Prometheus 服务器
- 用于检测应用程序代码的客户端库
- 支持短期工作的推送网关
- HAProxy、StatsD、Graphite 等服务的专用导出器。
- 一个用于处理警报的警报管理器
- 各种支持工具

![Prometheus Architecture](/kubernetes/resoures/img/architecture.svg)

## 安装Prometheus服务

1. 大多数官方 [Prometheus](https://prometheus.io/download/) 组件提供了预编译的二进制文件。
2. 所有 Prometheus 服务镜像都可以在 [Quay.io](https://quay.io/repository/prometheus/prometheus)或 [Docker Hub](https://hub.docker.com/r/prom/prometheus/)上找到。

> [!NOTE]
> 所有的安装配置教程在Prometheus官网都可以找到，安装启动也比较简单其中比较困难的是理解服务的配置文件。

## 配置文件

配置文件是Prometheus监控体系中比较重要的一部份了，需要理解配置文件选项功能，才能根据自身需求构建最佳实践的监控系统。
更详细的配置文件指南可参考: [Prometheus配置文件](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)。

### Prometheus配置文件骨架

prometheus 的主要配置都在 prometheus.yml（服务启动时读入）。典型顶层字段包括：

- global; 
- rule_files;
- alerting（alertmanagers 列表）;
- scrape_configs（多个 job 定义）;

以及其他可选项（remote_write/remote_read 等）。每个 job 定义如何发现和抓取 targets、以及 relabel/metric_relabel 规则等。

**基本骨架（概览）：**

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    cluster: "prod-01"

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
  - static_configs:
    - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  # 其它 job...
```

### 示例

作为Kubernetes原生监控系统，本身就己集成`kubernetes_sd_config`配置，以下是在Kubernetes集群中通过Deployment控制器布署监控Prometheus服务本身的实例。

- **编写Deployment清单**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prometheus
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: prometheus
data:
  prometheus-config.yaml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 30s
    scrape_configs:
      - job_name: prometheus
        honor_labels: true
        static_configs:
          - targets: ["localhost:9090"]
            labels:
              app: prometheus
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: prometheus
spec:
  selector: 
    matchExpressions:
      - key: app
        operator: In
        values: [prometheus]
  replicas: 1
  minReadySeconds: 5
  template:
    metadata: 
      name: prometheus
      namespace: prometheus
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus-350
          image: docker.io/prom/prometheus:v3.5.0
          imagePullPolicy: IfNotPresent
          command: ["/bin/prometheus"]
          args:
            - "--config.file=/etc/prometheus/prometheus-config.yaml"
            - "--storage.tsdb.path=/prometheus"
            - "--storage.tsdb.retention.time=24h"
            - "--web.enable-admin-api"
            - "--web.enable-lifecycle"
            - "--web.console.libraries=/usr/share/prometheus/console_libraries"
            - "--web.console.templates=/usr/share/prometheus/consoles"
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: data
              mountPath: /prometheus
            - name: cm-volume
              mountPath: /etc/prometheus
          readinessProbe:
            httpGet:
              port: 9090
              path: /query
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3
            successThreshold: 1
          livenessProbe:
            httpGet:
              port: 9090
              path: /query
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3
            successThreshold: 1
      securityContext:
        runAsUser: 0
      volumes:
        - name: data
          hostPath:
            path: /data/prometheus
        - name: cm-volume
          configMap:
            name: prometheus-config
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                - key: "kubernetes.io/hostname"
                  operator: In
                  values: ["vm-node-1"]
```

> [!NOTE]
> 上述清单定义了: Namespace、configMap、Deployment API资源。

通过`kubectl apply -f prometheus.yaml`创建资源。

- **通过svc暴露服务端口**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-svc
  namespace: prometheus
spec:
  selector:
    app: prometheus
  ports:
    - name: http
      port: 9191
      targetPort: 9090
  type: NodePort
```

