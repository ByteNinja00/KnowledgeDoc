# 亲和性

是 Kubernetes 中用于 Pod 调度亲和性（Affinity）与反亲和性（Anti-Affinity）策略 的配置字段，它用于控制 Pod 被调度到哪些 Node 或与哪些 Pod 进行共存或隔离。

## nodeAffinity

基于`node`亲和性调度。

### 软亲和性

软亲和性基于偏好来进行调度，尽量匹配，匹配则优先调度。

**FIELD: preferredDuringSchedulingIgnoredDuringExecution <[]PreferredSchedulingTerm>**

#### 字段结构

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: <int>
        preference:
          matchExpressions:
            - key: <string>
              operator: <In|NotIn|Exists|DoesNotExist|Gt|Lt>
              values: [<string>]
```

- **权重(weight)**

