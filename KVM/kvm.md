## 声明

> [!IMPORTANT]
> 本文中所有 **$** 符号后面连接的字符串均为变量。如：
> `$hostname` 代表主机名是一个变量。
>
## 目录

- **[克隆虚拟机](#1-克隆虚拟机)**
- **[创建虚拟机](#2-创建虚拟机)**
- **[进入虚拟机Console](#3-进入虚拟机控制台)**

## 1. 克隆虚拟机
>
> [!NOTE]
> 克隆之前需要提前关闭被克隆的虚拟机

```bash
virt-clone -o TEMPLATE-VM -n new-vm -f /vm-storage/vm-disk/new-vm.qcow2
```

## 2. 创建虚拟机

创建一台使用console控制台完成安装的虚拟机。

```bash
sudo virt-install --name k8s_master_template  \
--memory 4096 --vcpus 2 \
--metadata description="kubernetes master template" \
--location /res/ubuntu-20.04.6-live-server-amd64.iso,kernel=casper/hwe-vmlinuz,initrd=casper/hwe-initrd \
--disk /virtd/disk-img/k8s_master_template.qcow2,size=100 \
--network bridge=br0 --graphics none \
--console pty,target_type=serial \
--noautoconsole \
--extra-args "console=ttyS0,115200n8 serial"
```

> [!TIP]
> 在`--location`参数中指定内核按照当前发行版实际文件名，有的kernel可能是`vmlinuz`，而initrd可能是`initrd`

## 3. 进入虚拟机控制台

登陆KVM虚拟机控制台 **(console)**。

```bash
virsh console $hostname
```
