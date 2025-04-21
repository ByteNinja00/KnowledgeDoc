# Harbor镜像仓库的安装

Harbor 是一个开源镜像仓库，它通过策略和基于角色的访问控制来保护工件，确保镜像经过扫描且无漏洞，并将镜像签名为可信镜像。

## 硬件最小化需求

|资源|最小|建议|
|----|---|----|
|CPU|2   |4   |
|MEM|4 GB|8 GB|
|DISK|40 GB|160 GB|

## 软件需求

|软件|版本|描述|
|----|---|----|
|OpenSSL|Latest (optional)|用于生成Harbor的证书和密钥|

## 需要开放的网络端口

|协议|端口|描述|
|----|---|----|
|https|443|Harbor 门户和核心 API 在此端口接受 HTTPS 请求。可以在配置文件中更改此端口。|

## 下载Harbor

- 到[官方发布页面](https://github.com/goharbor/harbor/releases/tag/v2.13.0)下载:

```bash
wget https://github.com/goharbor/harbor/releases/tag/v2.13.0
```

- 解压

```bash
tar xzvf harbor-offline-installer-version.tgz
```

