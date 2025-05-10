# 创建桥接网络

KVM默认只有一个网络可供使用在 */etc/libvirt/qemu/networks/default.xml*，default网络是NAT模式即网络地址转换技术，有时我需要用到物理网络，所以需要一个桥接到物理网络的桥接网络。

- 在宿主机上创建一个桥接网络 */etc/netplan/50-cloud-init.yaml*:

```yaml
network:
  version: 2
  ethernets:
    eno1:
      dhcp4: false
  bridges:
    br0:
      interfaces: [eno1]
      addresses: [192.168.2.10/24]
      routes:
        - to: default
          via: 192.168.2.1
      nameservers:
        addresses: [192.168.2.1, 223.5.5.5]
        search: []
```

- 立即生效网络配置:

```bash
sudo netplan apply
```

- 创建libvirt网络 */etc/libvirt/qemu/networks/bridge.xml*:

```xml
<network>
 <name>br0</name>
 <forward mode='bridge'/>
 <bridge name='br0'/>
</network>
```

- 配置生效:

```bash
sudo virsh net-define /etc/libvirt/qemu/networks/bridge.xml
```

- 启动桥接网络:

```bash
sudo virsh net-start br0
```

- 设置为自启动:

```bash
sudo virsh net-autostart br0
```

- 查看虚拟网络:

```bash
virsh net-list
```

![list-net](/KVM/img/3.png)