# 用户证书及RBAC授权

在 Kubernetes 中，RBAC（Role-Based Access Control）主要是用来 授予权限给某些主体（Subject） 的。主体可以分为三类：

## RBAC授权主体

- User
- Group
- ServiceAccount

### 1. User（用户）

一般是人类用户（如: alex, alice）之类是外部系统通过如证书、SSO之类的认证，用户在Kubernetes本身没有对象表示。在我们使用kubectl时，集群会去查找`$HOME/.kube/config`这个配置文件内的用户就是这里指的用户类型。在证书内需要指定 **"CN"** 字段。

### 2. Group（用户组）

在 RBAC 中可以直接给组授权，这样组内所有成员都会拥有该权限，和 User（用户）一样，在证书 **O** 字段。

### 3. ServiceAccount（服务账户）

- 属于 Kubernetes 内部的“用户”，专门给 Pod 里的进程（应用/容器）使用。
- 当 Pod 运行时，如果挂载了 ServiceAccount 的 token，它就能以该身份访问 API Server。
- 常见场景：让某个 Pod 拥有对 ConfigMap、Secret、Deployment 等资源的操作权限。

## User/Group 通讯证书

本文主要讲如何颁发 **User/Group** 和集群通讯的证书及RBAC授权。

### 证书签名请求

`CertificateSigningRequest` 是Kubernetes集群内置的API资源。通过用户生的成私钥(key)和证书请求文件(csr)来给用户颁发证书。

> [!TIP]
> 除了用户私钥和证书请求文件之外，必须还要有当前集群的CA根证书。只有经过CA根证书签发的用户证书才能被集群校验成功。

假设当前我要为普通用户alex生成用户证书来和集群通信。

- **创建用户私钥**

```bash
openssl genrsa -out alex.key 2048
```

- **创建x.509证书签名请求**

> [!IMPORTANT]
> 这里有两个字段很关键，关系到RBAC授权的主本，CN 是用户的名称，O 是此用户所属的群组。

```bash
openssl req -new -key alex.key -out alex.csr -subj "/CN=alex"
```

- **创建 Kubernetes CertificateSigningRequest**
  
  - 使用base64对csr文件进行编码(必须是base64编码):
  
  ```bash
  cat alex.csr | base64 | tr -d "\n"
  ```

  - 创建 CertificateSigningRequest 并通过 kubectl 将其提交到 Kubernetes 集群。

  