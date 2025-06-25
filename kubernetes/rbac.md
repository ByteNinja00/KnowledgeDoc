# RBAC

RBAC（基于角色的访问控制，Role-Based Access Control） 是掌握集群权限管理的关键。

RBAC 是 Kubernetes 用来控制 “谁” 可以对 “什么资源” 进行 “什么操作” 的权限系统。

RBAC 的核心对象有 4 个：

| 对象                     | 说明                          |
| ---------------------- | --------------------------- |
| **Role**               | 定义在某个命名空间内的权限               |
| **ClusterRole**        | 定义跨命名空间或集群级别的权限             |
| **RoleBinding**        | 将 Role 绑定到用户或组（在某个命名空间）     |
| **ClusterRoleBinding** | 将 ClusterRole 绑定到用户或组（全局生效） |

## 概念

**主体：**

- 用户(User)

- 用户组(Group)

- 服务账号(ServiceAccount)

**Role / ClusterRole（角色）:**

即允许做什么，包含规则，规则规定对哪些资源做什么操作

**RoleBinding \/ ClusterRoleBinding（绑定）**

把某个角色跟某个主体绑定，即该主估估获得相应权限。
