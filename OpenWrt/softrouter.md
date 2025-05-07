# 软路由

安装OpenWrt最终的目的还是软路由，实现全家科学上网，第三方丰富的插件兼容多种主流的代理协议，还有内网穿透插件，一台OpenWrt软路由可以满足多种使用场景。

## 1. Hysteria2

[Hysteria2](https://v2.hysteria.network/docs/getting-started/Installation/)是 QUIC 协议提供支持，具体介绍概述可以前往官网参考。

要代理hy2协议，首先你得自建了一个机场或购买了订阅地址。

本文使用[Sing-box](https://sing-box.sagernet.org/),作为客户端代理hy2，并且只使用sing-box的linux客户端配置，个人感觉passwall插件不太好用。