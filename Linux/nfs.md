# NFS(Network File System)

**Network File System** 直译 **为网络文件系统** NFS 允许系统通过网络与其他系统共享目录和文件。通过使用 NFS，用户和程序可以像访问本地文件一样访问远程系统上的文件。

NFS提供一些显著的的功能：

- 本地主机的数据存储可以在另外一台网络上的主机设备上存储。
- 用户无需在每台网络计算机上都拥有单独的主目录。主目录可以设置在 NFS 服务器上，并在整个网络中可用。
- 网络上的其他设备可以使用软盘、CDROM 驱动器和 USB 拇指驱动器等存储设备。这可以减少整个网络中可移动媒体驱动器的数量。

## 安装

> [!TIP]
> 所有操作均在 **Ubuntu24.04 LTS** 系统下进行。

- 在终端提示符下输入如下命令安装:

```bash
sudo apt install nfs-kernel-server
```

- 自启动NFS网络文件系统服务：

```bash
sudo systemctl enable nfs-kernel-server.service --now
```

## 配置

NFS 服务涉及多个组件和协议，使用 多个端口，根据服务配置可能是固定的也可能是动态分配的。下面是 Ubuntu 24.04 默认 nfs-kernel-server 使用的端口:

| 服务组件                     | 协议      | 默认端口      | 说明             |
| ------------------------ | ------- | --------- | -------------- |
| **NFS 本体**               | TCP/UDP | 2049      | NFS 主服务端口（固定）  |
| **Portmapper / rpcbind** | TCP/UDP | 111       | 用于动态端口注册和映射    |
| **mountd**               | TCP/UDP | 动态端口（可配置） | 处理挂载请求         |
| **statd (rpc.statd)**    | TCP/UDP | 动态端口（可配置） | 文件锁定服务         |
| **lockd**                | TCP/UDP | 内核分配      | 文件锁支持，通常无需显式配置 |
| **rquotad**（可选）          | UDP     | 动态端口（可配置） | 磁盘配额服务，通常不启用   |

### 查看nfs正在使用的端口

```bash
sudo rpcinfo -p
```

### 设置固定端口

编辑 /etc/nfs.conf 或 /etc/default/nfs-kernel-server，加入或修改如下配置：

- 固定 mountd 端口

```bash
# /etc/nfs.conf
[mountd]
port=32767
```

或

```yaml
# /etc/default/nfs-kernel-server
RPCMOUNTDOPTS="--port 32767"
```

- 固定 statd（文件锁）端口

```bash
# /etc/default/nfs-common
STATDOPTS="--port 32765 --outgoing-port 32766"
```

- 配置完成重启服务

```yaml
sudo systemctl restart nfs-server
```

### 常用参数分类整理

- **访问权限控制**

| 参数          | 说明                       |
| ----------- | ------------------------ |
| `ro`        | 只读访问                     |
| `rw`        | 读写访问（默认推荐）               |
| `sync`      | 数据同步写入硬盘（安全，推荐）          |
| `async`     | 异步写入（性能高但不安全）            |
| `no_wdelay` | 立即写入，无延迟（只在 async 模式下有效） |
| `wdelay`    | 写入延迟，可能提高效率（默认）          |

- **身份映射（UID/GID 相关）**

| 参数               | 说明                                 |
| ---------------- | ---------------------------------- |
| `root_squash`    | 把客户端的 root 映射为 nobody（默认，**安全推荐**） |
| `no_root_squash` | 客户端的 root 拥有服务端 root 权限（危险！仅测试用途）  |
| `all_squash`     | 所有用户都映射为 nobody（适合匿名共享）            |
| `anonuid=<uid>`  | 指定匿名用户使用的 UID                      |
| `anongid=<gid>`  | 指定匿名用户使用的 GID                      |

- **目录相关**

| 参数                 | 说明                      |
| ------------------ | ----------------------- |
| `subtree_check`    | 检查子目录结构（默认启用，**有性能开销**） |
| `no_subtree_check` | 不检查目录层级变化（推荐）           |

- **网络/安全限制**

| 参数         | 说明                          |
| ---------- | --------------------------- |
| `insecure` | 允许从非特权端口（>1024）连接（默认不允许）    |
| `secure`   | 只允许从特权端口（<1024）连接（默认启用）     |
| `nohide`   | 允许客户端访问挂载在导出目录中的子挂载点（多重挂载用） |
| `crossmnt` | 客户端能跨挂载点访问子目录（多设备挂载时常用）     |

## 示例

配置文件在 **/etc/exports**:

```bash
# 允许整个 192.168.1.0/24 网段读写共享，关闭子目录检查
/srv/nfs/share 192.168.1.0/24(rw,sync,no_subtree_check)

# 只读共享给单个 IP，并做 root 映射保护
/srv/nfs/readonly 192.168.1.50(ro,sync,root_squash)

# 匿名共享，所有访问者映射为 UID 1000 用户
/srv/nfs/public *(rw,sync,all_squash,anonuid=1000,anongid=1000)
```