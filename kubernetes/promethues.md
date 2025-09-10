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

