# Samba文件共享

Samba 是一套基于 SMB（Server Message Block）协议的服务程序，允许 Linux/Unix 系统与 Windows 系统之间进行文件和打印共享。它可以让 Linux 主机像 Windows 文件服务器一样，方便 LAN 内的设备共享文件资源。

## 安装

1. 在 LuCI 中安装 luci-app-samba4 软件包。所有依赖项（例如 samba4-server）都会自动安装。
    - 或者通过 SSH 安装：opkg update && opkg install luci-app-samba4
    - 可选使用 opkg list | grep -i samba 检查可用版本
    ![installation samba](/OpenWrt/img/6.png)

2. 在 LuCI 的“服务”→“网络共享”页面上配置 Samba。建议使用 LuCI 进行初始配置，并且仅在需要时通过 LuCI 的“编辑模板”选项卡或从 shell 编辑 /etc/samba/smb.conf.template。LuCI 的基本配置指南如下：
    ![LuCI](/OpenWrt/img/smb.png)

3. 现在，将能够像 Network-attached_storage 一样读写 LAN 上的网络共享。例如，使用 Windows 文件资源管理器浏览路由器默认 IP 上名为“storage”的共享：\\192.168.1.1\storage\。

## 配置用户

1. 首先手动添加条目到 /etc/passwd 和 /etc/group 来创建Samba用户, 选择uid/gid的值>=1000，以避免与系统保留的<1000的值可能冲突。

*/etc/passwd*:

```bash
samba:x:1001:1001:samba:/SAMBA:/bin/false
```

> [!TIP]
> */etc/passwd* 配置文件以冒号分隔字段，以下是每个字段的含义:
>
> **用户名:密码:用户ID:组ID:用户信息:主目录:登录Shell**

*/etc/group*:

```bash
samba:x:1001:samba
```

> [!TIP]
> */etc/group* 配置文件以冒号分隔字段，以下是每个字段的含义:
>
> 组名:组密码:GID:该组的用户列表

2. 使用 `smbpasswd -a username` 为该用户创建并分配Samba密码（请注意，该命令将其写入 /etc/samba/smbpasswd 文件中）。

> [!WARNING]
> 如果出现：“不允许一个用户使用一个以上用户名与服务器或共享资源的多重连接。”报错。原因是Windows 会缓存你第一次输入的 Samba 登录用户名和密码，如果你后面再用另一个账号访问同一台 Samba 服务器，会被 Windows 拒绝连接。
> 解决方法： 打开命令提示符（CMD）输入`net use * /delete`