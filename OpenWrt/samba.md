# Samba文件共享

Samba 是一套基于 SMB（Server Message Block）协议的服务程序，允许 Linux/Unix 系统与 Windows 系统之间进行文件和打印共享。它可以让 Linux 主机像 Windows 文件服务器一样，方便 LAN 内的设备共享文件资源。

## Installation

1. 在 LuCI 中安装 luci-app-samba4 软件包。所有依赖项（例如 samba4-server）都会自动安装。
    - 或者通过 SSH 安装：opkg update && opkg install luci-app-samba4
    - 可选使用 opkg list | grep -i samba 检查可用版本

![installation samba](/OpenWrt/img/6.png)