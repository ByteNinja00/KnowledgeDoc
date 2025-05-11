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
>
> 我这里以`${变量}`的形式粘贴。

```json
{
    "log": { "disabled": false, "level": "info", "timestamp": true },
    "dns": {
        "servers": [
            {"tag": "defaults", "address": "223.5.5.5", "address_strategy": "prefer_ipv4", "detour": "direct"},
            {"tag": "google", "address": "8.8.8.8", "address_strategy": "prefer_ipv4", "detour": "hy2-out"}
        ],
        "rules": [
            {"domain_keyword": ["example.com", "example2.com"], "action": "route", "server": "defaults"},
            {"rule_set": ["geoip-cn", "geosite-cn"], "action": "route", "server": "defaults"}
        ],
        "final": "google",
        "strategy": "prefer_ipv4"
    },
    "route": {
        "rules": [
            {"rule_set": ["geoip-cn", "geosite-cn"], "action": "route", "outbound": "direct"},
            {"inbound": "tun-in", "action": "sniff", "timeout": "1s"},
            {"action": "sniff"},
            {"protocol": "dns", "action": "hijack-dns"}
        ],
        "rule_set": [
            {"tag": "geoip-cn","type": "remote","format": "binary","url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs", "download_detour": "hy2-out"},
            {"tag": "geosite-cn","type": "remote","format": "binary","url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs","download_detour": "hy2-out"}
        ],
        "final": "hy2-out",
        "auto_detect_interface": true
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "interface_name": "sing-box",
            "address": ["172.18.0.1/30"],
            "mtu": 9000,
            "auto_route": true,
            "platform": {
                "http_proxy": { "enabled": false, "server": "127.0.0.1", "server_port": 10809 }
            }
        }
    ],
    "outbounds": [
        {"type": "direct", "tag": "direct"},
        {
            "type": "hysteria2",
            "tag": "hy2-out",
            "server": "your.hysteria2.domain",
            "server_port": 25006,
            "password": "${youruser}: ${yourpasswd}",
            "tls": {"enabled": true, "server_name": "your.hysteria2.domain", "disable_sni": false, "insecure": false},
            "brutal_debug": false
        }
    ]
}
```

## 启动Hysteria2节点

