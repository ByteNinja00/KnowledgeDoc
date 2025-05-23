# Harbor镜像仓库的安装

Harbor 是一个开源镜像仓库，它通过策略和基于角色的访问控制来保护工件，确保镜像经过扫描且无漏洞，并将镜像签名为可信镜像。

参考Harbor[官方文档](https://goharbor.io/docs/2.13.0/install-config/)

> [!NOTE]
> Harbor 只能在 **X86** 平台上布署，官方是没有编译 **arm** 平台的二进制包。

## 硬件最小化需求

|资源|最小|建议|
|:----|:---|:----|
|CPU|2   |4   |
|MEM|4 GB|8 GB|
|DISK|40 GB|160 GB|

## 软件需求

|软件|版本|描述|
|:----|:---|:----|
|OpenSSL|Latest (optional)|用于生成Harbor的证书和密钥|
|Docker Engine|Version > 20.10|Docker 引擎安装|
|Docker Compose|Docker compose > 2.3|Docker Compose 是 Docker Engine 的一部分|

## 需要开放的网络端口

|协议|端口|描述|
|:----|:---|:----|
|HTTP |80  |Harbor 门户和核心 API 在此端口接受 HTTP 请求。您可以在配置文件中更改此端口。|
|https|443|Harbor 门户和核心 API 在此端口接受 HTTPS 请求。可以在配置文件中更改此端口。|

## 下载Harbor

- 到[官方发布页面](https://github.com/goharbor/harbor/releases/tag/v2.13.0)下载:

```bash
wget https://github.com/goharbor/harbor/releases/tag/v2.13.0
```

- 解压安装

```bash
tar xzvf harbor-offline-installer-version.tgz
```

## 生成HTTPS证书

Harbor默认没有附带HTTPS证书，对Harbor所有的请求不建议使用HTTP明文，以免被人网络抓包发起攻击。

生产环境建议使用权威的CA签发的HTTPS证书，测试、开发环境可以使用自签名的证书。

1. 生成自签名CA证书私钥:

```bash
openssl genrsa -out ca.key 4096
```

2. 生成自签名CA根证书:

```bash
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=GD/L=SZ/O=Devel/OU=OPS/CN=156753.xyz" \
 -key ca.key \
 -out ca.crt
```

3. 生成服务端证书私钥:

```bash
openssl genrsa -out 156753.xyz.key 4096
```

4. 生成服务端证书请求文件：

```bash
openssl req -sha512 -new \
    -subj "/C=CN/ST=GD/L=SZ/O=Posenal/OU=Devel/CN=156753.xyz" \
    -key 156753.xyz.key \
    -out 156753.xyz.csr
```

5. 生成 x509 v3 扩展文件:

```bash
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=156753.xyz
DNS.2=ocisg.156753.xyz
DNS.3=138.2.77.254
EOF
```

6. 使用CA根证书签名证书请求文件，连同 x509 v3 配置文件一起：

```bash
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in 156753.xyz.csr \
    -out 156753.xyz.crt
```

## 布署证书

1. 转换签发的服务器证书：

```bash
openssl x509 -inform PEM -in 156753.xyz.crt -out 156753.xyz.cert
```

2. 将服务器证书、密钥和 CA 文件复制到 Harbor 主机上的 Docker 证书文件夹中。必须先创建相应的文件夹。

```bash
cp 156753.xyz.cert /etc/docker/certs.d/156753.xyz/
cp 156753.xyz.key /etc/docker/certs.d/156753.xyz/
cp ca.crt /etc/docker/certs.d/156753.xyz/
```

3. 重启Docker服务:

```bash
sudo systemctl restart docker.service
```

## 配置Harbor

关于配置文件[参考官方文档](https://goharbor.io/docs/2.13.0/install-config/configure-yml-file/)

这边主要修改HTTPS连接和主机名，还有数据库登陆密码：

```yml
https:
  # https port for harbor, default is 443
  port: 443
  # The path of cert and key files for nginx
  certificate: /etc/docker/certs.d/15675.xyz/156753.xyz.cert
  private_key: /etc/docker/certs.d/1/etc/docker/certs.d/15675.xyz/156753.xyz.keyy

---
hostname: 156753.xyz

---
harbor_admin_password: admin123

---
database:
  # The password for the user('postgres' by default) of Harbor DB. Change this before any production use.
  password: admin123
```

## 运行安装脚本

- 如果安装不使用 Trivy:

```bash
sudo ./install.sh
```

- 使用 Trivy:

```bash
sudo ./install.sh --with-trivy
```

> [!NOTE]
> Trivy是一款全面且多功能的安全扫描程序。Trivy 的扫描程序可以查找安全问题，并确定可以发现这些问题的位置。
> 建议安装!!!

## 验证

安装完成后直接使用你的域名访问Harbor的登陆页面，帐号为：admin   密码：配置文件设置的登陆密码。