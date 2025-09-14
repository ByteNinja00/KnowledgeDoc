# Grafana数据看板

Grafana 是一个开源的数据可视化和监控平台，用于将各种数据源的数据进行实时可视化、分析和告警。它广泛应用于 DevOps、系统监控、应用性能监控 (APM) 和业务指标展示等场景。

## 核心功能

1. **数据可视化**

    - 支持多种图表：折线图、柱状图、饼图、表格、热力图等。

    - 可以对时间序列数据、指标数据和日志数据进行可视化。

2. **数据源支持**

    - 支持 Prometheus、InfluxDB、MySQL、PostgreSQL、Elasticsearch、Loki 等多种数据源。

    - 可以同时接入多个数据源，进行跨数据源查询。

3. **仪表盘 (Dashboard)**

    - 可以创建自定义仪表盘，用于展示系统、应用或业务指标。

    - 支持模板变量，使仪表盘可动态展示不同主机、服务或时间段的数据。

4. **告警 (Alerting)**

    - 可以对指标设置告警规则，当数据超过阈值时，通过邮件、Slack、Webhook 等方式通知。

    - 用户管理与权限控制

5. **支持组织、团队管理。**

    - 可对仪表盘和数据源设置访问权限。

6. **插件扩展**

    - 丰富的社区插件：面板插件、数据源插件、应用插件。

    - 可以自定义开发插件满足特定需求。

## 典型应用场景

- 运维监控：实时监控服务器、容器、数据库、网络等。

- 应用性能监控 (APM)：分析应用请求、延迟、错误率等。

- 业务数据分析：可视化业务指标，如订单量、用户行为等。

- 日志分析：结合 Loki 等日志数据源进行集中日志查询和分析。

## Grafana 与 Prometheus 配合

- Prometheus 负责数据采集和存储。

- Grafana 负责数据可视化和告警展示。

- 常见架构：Prometheus → Grafana → Dashboard/告警通知。

## 安装Grafana in Kubernetes

[Grafana](/https://grafana.com/docs/grafana/latest/)文档参考。

以下布署环境均在Kubernetes环境操作。

- **布署grafana deployment清单**

> [!TIP]
> 以下deployment假设己经创建`prometheus`名字空间，执行：`kubectl apply -f grafana.yaml --namespace prometheus`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: grafana
  name: grafana
spec:
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      securityContext:
        fsGroup: 472
        supplementalGroups:
          - 0
        runAsUser: 0
      containers:
        - name: grafana
          image: docker.io/grafana/grafana:12.1.1
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3000
              name: http-grafana
              protocol: TCP
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /robots.txt
              port: 3000
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 30
            successThreshold: 1
            timeoutSeconds: 2
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 3000
            timeoutSeconds: 1
          resources:
            requests:
              cpu: 250m
              memory: 750Mi
          volumeMounts:
            - mountPath: /var/lib/grafana
              name: grafana-volume
      volumes:
        - name: grafana-volume
          hostPath:
            path: /data/grafana
      nodeName: vm-node-2
```

- **创建svc**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  ports:
    - port: 3000
      protocol: TCP
      targetPort: http-grafana
  selector:
    app: grafana
  sessionAffinity: None
  type: NodePort
```

> [!TIP]
> 通过`kubectl -n prometheus get svc -o wide`找到NodePort暴露的端口，在浏览器输入节点IP：端口访问web UI
> 登陆账号：密码（admin:admin），第一次登陆会要求修改密码。
> grafana默认数据库使用**SQLite 3**。