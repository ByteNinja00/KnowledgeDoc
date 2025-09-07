# RBAC签权

RBAC（Role-Based Access Control），基于角色的访问控制。Kubernetes 中的 RBAC 主要解决两个问题：

1. 谁（Who）：哪些用户、用户组或 ServiceAccount。
2. 能做什么（What）：在什么资源（Pod、Deployment、ConfigMap 等）上做哪些操作（get、list、create、delete 等）。

