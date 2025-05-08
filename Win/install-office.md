# 免费激活 MicroSoft 官方 Office

1. 官方的布署工具: [https://www.microsoft.com/en-us/download/details.aspx?id=49117](https://www.microsoft.com/en-us/download/details.aspx?id=49117)
2. 官方自定义配置工具: [https://config.office.com/deploymentsettings](https://config.office.com/deploymentsettings)
3. 基于KMS的 GVLK: [https://learn.microsoft.com/zh-cn/deployoffice/vlactivation/gvlks](https://learn.microsoft.com/zh-cn/deployoffice/vlactivation/gvlks)

## 下载官方布署工具

![deploytools](/Win/Pictu/1.png)

按提示和路径一步一步安装完毕。

## 导出自定义配置XML文件

- 选择安装激活版本

![version](/Win/Pictu/2.png)

- 选择更新频道

![channel](/Win/Pictu/3.png)

- 选择安装的应用

![application](/Win/Pictu/4.png)

- 选择安装语言

![lang](/Win/Pictu/5.png)

- 导出配置文件

![export](/Win/Pictu/6.png)

## 安装激活

将导出的配置文件复制到安装布署工具的根目录，执行以下命令：

- 进入安装布署工具的根目录

```powershell
cd D:\Office Install
d:
```

- 下载安装

```powershell
setup.exe /download configure.xml
```

- 完成安装配置

```powershell
setup.exe /configure configure.xml
```

- 激活Office

```powershell

```

> [!NOTE]
> 要以管理员身份打开**Powershell**或**CMD**