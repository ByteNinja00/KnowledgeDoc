# 用户证书及RBAC授权

在 Kubernetes 中，RBAC（Role-Based Access Control）主要是用来 授予权限给某些主体（Subject） 的。主体可以分为三类：

## 1. User（用户）

一般是人类用户（如: alex, alice）之类是外部系统通过如证书、SSO之类的认证，用户在Kubernetes本身没有对象表示。在我们使用kubectl时，集群会去查找`$HOME/.kube/config`这个配置文件内的用户就是这里指的用户类型。

