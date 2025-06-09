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
