# 配置和使用

成功安装OpenWrt软路由之后，并不能直接使用，需要配置一些基本的配置，比如网络配置，硬盘扩容等等。

## 网络配置

OpenWrt 使用 UCI 网络子系统（UCI network subsystem）进行中心化的配置管理，配置都保存在文件 /etc/config/network 中。 该 UCI 子系统负责定义不同的交换机 VLAN、接口配置和网络路由。 在完成配置后，需要重新加载 (reload) 或重启 (restart) network 服务，新的配置才会生效。

```c
config interface 'loopback'
        option device 'lo'
        option proto 'static'
        option ipaddr '127.0.0.1'
        option netmask '255.0.0.0'

config globals 'globals'
        option ula_prefix 'fda1:2724:d01a::/48'

config device
        option name 'br-lan'
        option type 'bridge'
        list ports 'eth1'

config interface 'eth1'
        option device 'br-lan'
        option proto 'static'
        option ipaddr '192.168.2.1'
        option netmask '255.255.255.0'
        option ip6assign '60'

config interface 'wan'
        option device 'eth0'
        option proto 'dhcp'

config interface 'wan6'
        option device 'eth1'
        option proto 'dhcpv6'
````

配置文件主要看 **device** 和 **interface**：

- device：配置流量经过软路由的设备需要桥接到哪个接口，`list ports 'eth1'` 表示br-lan桥接到eth1接口。
- interface：这里是定义接口参数，如配置IP地址。

## 磁盘扩容

OpenWrt在写入固件的时候，根分区只有100M的分区，大量磁盘空间没有利用。所以要对根分区进行扩容。

![img](/OpenWrt/img/1.png)

- 更新opkg源

```bash
opkg update
```

- 安装扩容工具包

```sh
opkg install parted losetup resize2fs
```

- 扩容磁盘

```sh
parted resizepart 2 100%
```

![img](/OpenWrt/img/2.png)

> [!NOTE]
> 可以看到设备sda己经扩容

- 扩容挂载的文件系统

![img](/OpenWrt/img/3.png)

> [!NOTE]
> 磁盘分区己经扩容，但是文件系统没有变。

```sh
losetup /dev/loop1 /dev/sda2
```

> [!TIP]
> 这一步是把 /dev/loop1 绑定到 /dev/sda2，目的是把/dev/loop1当作中间层，不直接操作己经挂载了根分区的 /dev/sda2

```sh
resize2fs -f /dev/loop1
```

![img](/OpenWrt/img/4.png)

## 防火墙设置

OpenWrt系统防火墙是基于**iptables**,Openwrt支持两种途径配置 iptables ,一种就是 Openwrt 自己的 UCI 方式,另一种就是传统的 Linux 方式。

本文是通过UCI 的方式配置 /etc/config/firewall 这个文件来完成的。

**firewall文件结构:**

```bash
defalt
    系统默认防火墙设置

zone
    firewall将网络接口定义不同的防火墙区域

forwarding
    位于的 zone 下面, 主要作用是允许数据封包转发。

rule 及 redirect

    可以看作是 zone 子集, 用来扩展进一步的封包限制。
```