# Harbor 镜像仓库的安装

## 前置条件
1. **操作系统**: 确保运行环境为 Linux 系统（如 CentOS 或 Ubuntu）。
2. **Docker**: 安装并配置 Docker。
3. **Docker Compose**: 安装 Docker Compose。
4. **硬件要求**:
    - CPU: 2 核或以上
    - 内存: 4GB 或以上
    - 磁盘: 至少 40GB 可用空间

## 安装步骤

### 1. 下载 Harbor 安装包
从 [Harbor 官方发布页面](https://github.com/goharbor/harbor/releases) 下载最新版本的安装包：
```bash
wget https://github.com/goharbor/harbor/releases/download/v<版本号>/harbor-offline-installer-v<版本号>.tgz
```

### 2. 解压安装包
```bash
tar -xvf harbor-offline-installer-v<版本号>.tgz
cd harbor
```

### 3. 配置 Harbor
编辑 `harbor.yml` 文件，根据需求修改以下配置：
- `hostname`: 设置为服务器的域名或 IP 地址。
- `https`: 如果需要启用 HTTPS，配置证书路径。

示例配置：
```yaml
hostname: harbor.example.com
http:
  port: 80
# https:
#   port: 443
#   certificate: /path/to/cert
#   private_key: /path/to/key
```

### 4. 安装 Harbor
运行安装脚本：
```bash
./install.sh
```

### 5. 验证安装
访问 `http://<hostname>`，默认管理员账号为 `admin`，密码为 `Harbor12345`。

## 常见问题
- **端口冲突**: 确保 80 或 443 端口未被占用。
- **登录失败**: 检查配置文件和日志，确保服务正常运行。

## 参考文档
- [Harbor 官方文档](https://goharbor.io/docs/)
