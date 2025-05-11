# 安装sing-box代理

**[sing-box](https://sing-box.sagernet.org/)** 是一个开源的网络代理平台，作为一个玩软路由的，不搞点梯子代理软件，等于白折腾了。
OpenWrt本身软件包有一些支持sing-box的插件，但是本人觉得不是很好用。还不如直接用sing-box客户端手搓配置文件，省了安装第三方插件。

## 安装Sing-box

由于官方脚本只支持RPM和APT安装，所以这边只能下载二进制包来安装。

下载好的二进制压缩包，放入网络共享目录，如 **[Samba](/OpenWrt/samba.md)**，只要能上传到OpenWrt软路由目录下，怎么方便怎么来。

- 创建安装目录

```bash
mkdir /sing-box
```

- 解压安装

```bash
tar zxvf sing-box-1.11.4-linux-amd64.tar.gz -C /sing-box/ && mv /sing-box/sing-box-1.11.4-linux-amd64/sing-box /sing-box/ && rm -rf /sing-box/sing-box-1.11.4-linux-amd64
```

- 手搓配置文件

配置文件这块有点难度啊，新手要学习要花点时间，官网上的文档有点混乱，主要人家也是代码经常更新，配置文件差一多一个版本就要废弃一些配置语法，要紧跟官方文档，这也侧面说明了，这个GITHUB项目非常活跃。

> [!NOTE]
> 我这里主要是用的Hysteria2协议，1.11.4版本的可以作为模板参考。
> 其中我自己的代理节点，肯定是不能公开的哈，替换成自己的机场或订阅节点。
