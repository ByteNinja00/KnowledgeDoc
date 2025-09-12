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

以下是在Kubernetes集群下，布署一个Deployment控制器的 **Prometheus服务，** 监控Prometheus服务本身。

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

### kubernetes_sd_config

Kubernetes SD 配置从 Kubernetes集群REST API 抓取指标并始终与集群状态保持同步。

> [!TIP]
> 要理解Prometheus配置文件，必须提前了解一下Go语言的正表达式，不然`relabel_config`会把自己看得云里雾里。
> 如下表：

***基本正则用法***

|符号|含义|
|----|----|
|`.`|任意单个字符|
|`*`|前面的字符 0 次或多次|
|`+`|前面的字符 1 次或多次|
|`?`|前面的字符 0 次或 1 次|
|`()`|分组，配合 ${1} 用作替换|
|`|`|
|^|行开头|
|$|行结尾|

以下假设要监控 **Kubernetes Nodes** 对象。

- **创建`namespace`**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prometheus
```

- **创建服务帐号(sa)**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: prometheus
automountServiceAccountToken: true
```

- **创建RBAC策略**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources: ["nodes", "nodes/metrics"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: prometheus
```

- **创建configMap**

```yaml
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
      - job_name: "kubernetes-nodes"
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
        authorization:
          credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
          - role: node
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
```

- **创建`Prometheus Deployment`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: prometheus
  labels:
    app: prometheus
    kind: monitor
spec:
  replicas: 1
  minReadySeconds: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge:  25%
      maxUnavailable: 30%
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      name: prometheus
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
        - name: prometheus-server
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
              name: prom-http
          volumeMounts:
            - name: data
              mountPath: /prometheus
            - name: cm-volume
              mountPath: /etc/prometheus
          resources:
            limits:
              cpu: 2
              memory: "4Gi"
            requests:
              cpu: 0.5
              memory: "1Gi"
          livenessProbe:
            httpGet:
              port: 9090
              path: /-/healthy
              scheme: HTTP
            initialDelaySeconds: 2
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 2
            successThreshold: 1
          readinessProbe:
            httpGet:
              port: 9090
              path: /-/healthy
              scheme: HTTP
            initialDelaySeconds: 2
            timeoutSeconds: 3
            failureThreshold: 2
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
> 以上是监控`Prometheus`服务本身和`kubernetes_sd_config`中的`Node`对象。
> 增加监控Kubernetes资源对象，相应的需要在`RBAC`增加授权和`configMap`增加监控对象。

[kubernetes_sd_config 配置](/kubernetes/resoures/mainfest/prometheus-cm.yaml)

### `relabel_config` 和 `metric_relabel_config`

这两个配置容易混淆，因为名字很相似，但在 Prometheus 中它们作用在完全不同的阶段。可以按数据流来理解。

- **relabel_config**

作用阶段：抓取目标（Target）之前

- 也就是说，它是在 Prometheus 抓取 scrape targets 之前对 target 标签进行处理。
- 主要用于 修改、过滤、动态生成抓取目标。

- **metric_relabel_config**

作用阶段：抓取指标之后，写入 TSDB 之前

- 对 抓取回来的每条 metric 的 label 做处理。
- 可以理解为针对指标级别的过滤和修改。

