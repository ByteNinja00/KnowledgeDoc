# 搭建DNS控制台

## 背景

客户需求在内网搭建一主一备DNS服务，刚开始客户的需求并没有明确，所以使用windows server 2019 内置的DNS服务来解决客户的DNS服务，但是后续客户需要DNS带控制台，因此选择bind+webMin方案。

## 1. 布署安装

| 主机名称       | IPv4地址          | 组件                     | 系统        |
| ---------- | --------------- | ---------------------- | --------- |
| dns-master | 192.168.182.130 | bind、bind-utils、webmin | CentOS7.9 |
| dns-slave  | 192.168.182.131 | bind、bind-utils        | CentOS7.9 |

### 1.1. 主机环境设置

布署安装前，先对主机进行环境的配置。

- 设置Master和Slave主机名

```bash
# Master节点
hostnamectl set-hostname dns-master

# Slave节点
hostnamectl set-hostname dns-slave
```

- 关闭防火墙

```bash
systemctl disable firewalld.service --now
```

- 关闭`iptables`

```bash
iptables -F && iptables -X
```

- 保存当前己清空的iptables规则，避免下次重启重新加载

```bash
iptables-save
```

### 1.2. 安装DNS服务

- 更新系统

```bash
yum -y update
```

- 安装bind、bind-utils

```bash
yum install bind bind-utils -y
```

- 启动DNS服务并标记为随开机自启

```bash
systemctl enable named.service --now
```

> 检查DNS服务是否己经`active`: `systemctl status named.service`

### 1.3. 安装Webmin

Webmin 是一款基于 Web 的系统管理工具，适用于类 Unix 服务器和服务，全球每年安装量约 1,000,000 台。使用它，可以配置操作系统内部组件，例如用户、磁盘配额、服务或配置文件，以及修改和控制开源应用程序，例如 BIND DNS 服务器、Apache HTTP 服务器、PHP、MySQL 等等。

- 备份旧repo仓库目录，创建新的repo仓库目录。

```bash
mv /etc/yum.repo.d{,.bak} && mkdir /etc/yum.repo.d
```

- 创建Webmin存储库文件

```bash
[Webmin]
name=Webmin Distribution Neutral
mirrorlist=https://download.webmin.com/download/yum/mirrorlist
enabled=1
```

- 导入 Webmin GPG 密钥

```bash
rpm --import https://download.webmin.com/jcameron-key.asc
```

- 安装 Webmin

```bash
yum install webmin -y
```

## 2. 配置主备

**主服务器（Master）**：保存域名的**原始数据文件（zone file）**，由管理员手动编辑。

**从服务器（Slave）**：从主服务器**自动同步 zone 数据**，不直接编辑 zone 文件。

当主服务器不可用时，从服务器仍能继续提供解析服务。

假设需要管理的域为：**example.com**

### 2.1. 主DNS服务器配置

1. 修改主配置文件`/etc/named.conf`；

```bash
zone "example.com" IN {
    type master;
    file "example.com.zone";
    allow-transfer { 192.168.182.131; };  // 允许从服务器传输zone数据
    also-notify { 192.168.182.131; };     // 当zone更新时通知从服务器
};
```

2. 创建zone文件；

```bash
$TTL 86400
@   IN  SOA dns-master.example.com. admin.example.com. (
        2025103101  ; 序列号（修改zone后需+1）
        3600        ; 刷新时间
        1800        ; 重试时间
        1209600     ; 过期时间
        86400 )     ; 最小TTL
;
@       IN  NS      dns-master.example.com.
@       IN  NS      dns-slave.example.com.
dns-master IN A      192.168.182.130
dns-slave  IN A      192.168.182.131
www        IN A      192.168.182.20
```

3. 检查配置并启动；

```bash
named-checkconf
named-checkzone example.com /var/named/example.com.zone
systemctl restart named
```

### 2.2. 从DNS服务器配置

1. 修改 `/etc/named.conf`；

```bash
zone "example.com" IN {
    type slave;
    masters { 192.168.182.130; };  // 指定主服务器地址
    file "slaves/example.com.zone";  // 同步文件存放路径
};
```

2. 确保有`/var/named/slaves`这个目录；

```bash
mkdir -p /var/named/slaves
chown named:named /var/named/slaves
```

3. 检查配置并启动；

```bash
named-checkconf
systemctl restart named
```

### 2.3. 验证同步是否成功

- 在从DNS服务器上查看

```bash
journalctl --unit named.service --no-pager | grep 'transfer'
```

- 出现如下信息表示成功

```bash
transfer of 'case.com/IN' from 192.168.182.130#53: Transfer completed:
```

- 使用nslookup验证

```bash
nslookup dns-master.example.com 192.168.182.130
```

## 3. 开启递归查询

**递归查询（Recursive Query）** 指的是：  
客户端（通常是本地解析器）向 DNS 服务器发出一个查询请求，要求 **服务器帮它查到最终的 IP 地址结果**。

- 客户端只发出一次请求；

- DNS 服务器负责代客户端去其他 DNS 服务器（根、顶级域、权威服务器）一层层查询；

- 最后返回结果给客户端。

| 查询类型     | 特点                                 |
| -------- | ---------------------------------- |
| **递归查询** | 客户端→本地DNS，DNS全程代查到底（常见于客户端发给本地DNS） |
| **迭代查询** | DNS服务器之间的查询，返回“你去问谁”信息             |

在 **BIND 配置文件 `/etc/named.conf`**（或 `/etc/bind/named.conf.options`）中，有几个关键参数控制递归行为：

```bash
options {
    recursion yes;           // 开启递归（默认开启）
    allow-recursion { any; };// 允许哪些客户端使用递归
};
```

- `recursion yes;` —— 表示该 DNS 可以为客户端执行递归查询；

- `allow-recursion { any; };` —— 指定允许执行递归查询的客户端（默认仅 localhost）。

### 3.1. BIND 的递归查询辅助配置

指定上游转发服务器（可加速）如果不想从根查起，可设置 **转发模式（Forwarders）**：

```bash
options {
    recursion yes;
    forwarders { 8.8.8.8; 114.114.114.114; };
    forward only; // 只向上游转发，不再向根查
};
```

> 这样 BIND 不再从根服务器查，而是把递归查询交给上游公共 DNS。
