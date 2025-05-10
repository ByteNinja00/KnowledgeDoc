# KVM虚拟化平台安装

KVM平台虚拟化首先需要了解QEMU是什么，KVM是什么，它们两者之间是什么关系。

- QEMU是一个开源的通用系统模拟器，可以完全模拟一个计算机系统（CPU、内存、磁盘、网络等）支持“纯软件模拟”（不依赖硬件虚拟化），但性能较差。
- KVM是 Linux 内核模块，使得 Linux 本身变成一个 虚拟机管理器（Hypervisor），依赖于 CPU 的虚拟化扩展（Intel VT-x 或 AMD-V）。本身只提供内核层面的虚拟化能力，不负责用户空间的设备模拟。

**一句话概括**：KVM 提供虚拟化能力（硬件支持），QEMU 提供虚拟机模拟器（用户空间工具），两者组合起来实现高效的虚拟化平台。

## QEMU+KVM安装

- 检查当前操作系统CPU 支持 VT-x 或 AMD-V:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

> [!TIP]
> 输出大于0：表示支持硬件虚拟化
>
> 如果返回0：需要BIOS开启该功能或硬件不支持该功能。

- 安装所需要的软件包：

```bash
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

|包名|功能|
|----|----|
|`qemu-kvm`|QEMU 虚拟机与 KVM 加速器|
|`libvirt-daemon-system`|提供 libvirt 的系统级管理服务|
|`bridge-utils`|用于配置网络桥接|
|`libvirt-clients`|virsh 等命令行工具|

- 查看KVM内核模块是否成功加载：

```bash
lsmod | grep kvm
```

> [!NOTE]
> 正常的话应该可以看到 kvm_intel 或 kvm_amd 模块在终端返回。
>
> 查看KVM设备: `ls -l /dev/kvm`
>
> 测试是否可用: `kvm-ok`
