# OpenWrt安装

OpenWrt是一款开源的软路由固件，支持目前主流路由器的固件安装。参考官方固件列表: [支持的硬件列表](https://openwrt.org/toh/views/toh_fwdownload?dataflt%5B0%5D=supported%20current%20rel_%3D24.10.1)。

当然也支持刷x86设备固件。

## 安装

本文是以J4125机器作为软路由来安装的，该设备是x86机型，固件安装的媒介有多种方法，如果是移动盘U盘作为固件安装，则直接用刻录工具把镜像烧录即可。

但如果是作为SSD或非移动硬盘来进行固件的安装，则需要做以下操作。

### 准备工作

1. PE启动工具，如老毛桃等。
2. 下载[OpenWrt固件](https://downloads.openwrt.org/releases/24.10.1/targets/x86/64/),解压出img镜像文件。
3. 写盘工具

### 制作PE启动U盘

制作PE盘想必做过重装win系统的都不陌生，这里不多赘述。之后把下载的OpenWrt固件和写盘工具放入PE启动盘的根目录。

![root alt](/OpenWrt/img/老毛桃U盘%20(D_)%202025_5_7%202_49_30.png)

### 启动PE盘

将PE启动盘插入需要写入OpenWrt固件的设备，并在开机启动的时候选择U盘启动，进入PE。

### 刷入OpenWrt固件

进入PE分区工具，删除所有需要安装OpenWrt硬盘的分区，之后点击保存。

![disk alt](/OpenWrt/img/fenqu.png)

打开写盘工具(DiskImg.exe),选择将需要刷入固件的硬盘，之后重启即可。