# Samba文件共享

Samba 是一套基于 SMB（Server Message Block）协议的服务程序，允许 Linux/Unix 系统与 Windows 系统之间进行文件和打印共享。它可以让 Linux 主机像 Windows 文件服务器一样，方便 LAN 内的设备共享文件资源。

## 安装

1. 在 LuCI 中安装 luci-app-samba4 软件包。所有依赖项（例如 samba4-server）都会自动安装。
    - 或者通过 SSH 安装：opkg update && opkg install luci-app-samba4
    - 可选使用 opkg list | grep -i samba 检查可用版本

    ![installation samba](/OpenWrt/img/6.png)

2. 在 LuCI 的“服务”→“网络共享”页面上配置 Samba。建议使用 LuCI 进行初始配置，并且仅在需要时通过 LuCI 的“编辑模板”选项卡或从 shell 编辑 /etc/samba/smb.conf.template。LuCI 的基本配置指南如下：
    - Interface：Lan
    - Workgroup：WORKGROUP
    - Enable Extra Tuning：默认勾选（以获得更大的吞吐量。请注意，对于 Apple Time Machine，请勿选中，因为它与 macOS 不兼容）
    - Shared Directories：点击添加
    - Name：输入共享文件夹的名称（例如路由器名称）
    - Path：/mnt/sda1（输入驱动器的挂载点，如果仍需要挂载驱动器，请单击路径→）
    - Browseable：checked
    - Read-only: unchecked
    - Force Root：默认己勾选（注意：如果你的 LAN 是安全的，请使用，否则请按照以下部分中的描述设置用户帐户，并在“允许的用户”下输入）
    - Allow guests：默认己勾选（除非使用如上所述的用户帐户）
    - Create Mask：0666
    - Directory Mask: 0777
    - 保存并应用

3. 现在，将能够像 Network-attached_storage 一样读写 LAN 上的网络共享。例如，使用 Windows 文件资源管理器浏览路由器默认 IP 上名为“storage”的共享：\\192.168.1.1\storage\。

## 配置
