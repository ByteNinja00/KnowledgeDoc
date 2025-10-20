# 在CentOS7.9安装bind9+webmin实现控制台操作DNS服务

在 CentOS 7 上安装 BIND9 和 Webmin 涉及两个主要部分：安装 BIND9（DNS 服务器）然后安装 Webmin（基于 Web 的管理界面）。

## 1. 前置工作

因为Webmin和bind9都有自己的服务端口，选择放行端口或关闭防火墙确保能正常对外提供服务。

- 关闭防火墙和iptables(可选： 进行端口放行):

```bash
systemctl disable firewalld.service --now
```

并且清空iptables规则和删除自定义链表:

```bash
iptables -F && iptables -X
```

保存当前己清空的iptables规则，避免下次重启重新加载:

```bash
iptables-save
```

## 2. 安装Bind9

- 更新系统:

```bash
yum update -y
```

- 安装 BIND9 和 BIND-utils:

```bash
yum install bind bind-utils -y
```

- 启动DNS服务并标记为随开机自启:

```bash
systemctl enable named.service --now
```

> [!IMPORTANT]
> 检查DNS服务是否己经`active`: `systemctl status named.service`

## 3. 安装Webmin

Webmin 是一款基于 Web 的系统管理工具，适用于类 Unix 服务器和服务，全球每年安装量约 1,000,000 台。使用它，可以配置操作系统内部组件，例如用户、磁盘配额、服务或配置文件，以及修改和控制开源应用程序，例如 BIND DNS 服务器、Apache HTTP 服务器、PHP、MySQL 等等。

- 创建Webmin存储库文件:

```bash
vim /etc/yum.repos.d/webmin.repo
```

- 写入配置

```bash
[Webmin]
name=Webmin Distribution Neutral
mirrorlist=https://download.webmin.com/download/yum/mirrorlist
enabled=1
```

- 导入 Webmin GPG 密钥:

```bash
rpm --import https://download.webmin.com/jcameron-key.asc
```

- 安装 Webmin:

```bash
yum install webmin -y
```

## 4. 使用Webmin管理DNS服务

打开 Web 浏览器并导航至https://Your_Server_IP_Address:10000。 可能会看到自签名证书警告，但可以绕过它。

登陆用户: root(或自己的系统用户)，密码：系统用户登陆蜜码。

### 4.1 配置DNS

