## 网络配置

OpenWrt 使用 UCI 网络子系统（UCI network subsystem）进行中心化的配置管理，配置都保存在文件 /etc/config/network 中。 该 UCI 子系统负责定义不同的交换机 VLAN、接口配置和网络路由。 在完成配置后，需要重新加载 (reload) 或重启 (restart) network 服务，新的配置才会生效。
