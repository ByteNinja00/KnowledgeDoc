# RBAC签权

RBAC（Role-Based Access Control），基于角色的访问控制。Kubernetes 中的 RBAC 主要解决两个问题：

1. 谁（Who）：哪些用户、用户组或 ServiceAccount。
2. 能做什么（What）：在什么资源（Pod、Deployment、ConfigMap 等）上做哪些操作（get、list、create、delete 等）。

## API 对象

RBAC API 声明了四种 Kubernetes 对象：Role、ClusterRole、RoleBinding 和 ClusterRoleBinding。

### Role

- 作用范围：命名空间级别
- 定义一组权限规则，描述允许对哪些 资源 做哪些 操作。

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]          # 空字符串表示 core API group，比如 Pod、Service
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

> [!NOTE]
> 这里定义了一个 pod-reader 角色，只能在 dev 命名空间下读取 Pod。

### ClusterRole

- 作用范围：集群级别
- 可以定义跨命名空间的权限，也可以定义命名空间内的权限。
- 一般用于：
  - 集群级资源（如 nodes、persistentvolumes）
  - 或者想在多个 namespace 复用的权限

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin-view
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
```

### RoleBinding

- 作用范围：命名空间级别
- 把一个 Role（或 ClusterRole）绑定给用户、用户组或 ServiceAccount。

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: dev
subjects:                      # 绑定的主体
- kind: User                   # 还可以是 ServiceAccount 或 Group
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:                       # 引用的角色
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

> [!NOTE]
> 这表示用户 alice 在 dev 命名空间中有读取 Pod 的权限。

### ClusterRoleBinding

- 作用范围：集群级别
- 把一个 ClusterRole 绑定给用户/组/ServiceAccount，全局生效。

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-read-nodes
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin-view
  apiGroup: rbac.authorization.k8s.io
```

> [!NOTE]
> 这表示用户 bob 在整个集群中都有读取 Node 的权限。

## RBAC 权限生效关系图

![rbac](/kubernetes/object/img/rbac.png)

## 组合方式

在 Kubernetes RBAC 中，这四个资源是核心组件，它们的组合方式决定了用户、服务账号或组在不同作用域下的权限。

### Role + RoleBinding

开发人员 alice 只能在 dev 命名空间查看 Pods。

```yaml
# Role：定义在 dev 命名空间对 Pods 的只读权限
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

---
# RoleBinding：把 Role 绑定给用户 alice
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: dev
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

> [!NOTE]
> alice 只能在 dev 命名空间里看 Pods，其他命名空间没权限。

### ClusterRole + RoleBinding

CI/CD 的 ServiceAccount 需要管理 configmaps 和 secrets，但仅限 ci 命名空间。

```yaml
# ClusterRole：定义可以管理 configmaps 和 secrets
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ci-secret-manager
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "delete"]

---
# RoleBinding：在 ci 命名空间把 ClusterRole 绑定给 ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-secret-binding
  namespace: ci
subjects:
- kind: ServiceAccount
  name: ci-bot
  namespace: ci
roleRef:
  kind: ClusterRole
  name: ci-secret-manager
  apiGroup: rbac.authorization.k8s.io
```

> [!NOTE]
> ServiceAccount ci-bot 可以在 ci 命名空间操作 Secrets 和 ConfigMaps，但不能跨命名空间。

### ClusterRole + ClusterRoleBinding

运维人员 bob 需要在整个集群中查看所有 Pods。

```yaml
# ClusterRole：全局查看 pods 权限
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-viewer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

---
# ClusterRoleBinding：绑定给用户 bob
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: bob-pod-view
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-viewer
  apiGroup: rbac.authorization.k8s.io
```

> [!NOTE]
> bob 可以在 所有命名空间里查看 Pods。

### 总结

- Role + RoleBinding: 作用在单命名空间，权限范围最小。

- ClusterRole + RoleBinding: 权限定义全局的，但只在某个命名空间生效。

- ClusterRole + ClusterRoleBinding: 权限全局且跨所有命名空间。

- Role + ClusterRoleBinding: **不存在**，Role 只能用 RoleBinding。