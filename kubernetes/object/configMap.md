# configMap对象

configMap存储让其它对象可引用其配置的API对象。有两个字段**data**和**binaryData**。

- data：用来保存UTF-8字符串。
- binaryData：用来保存二进制数据作为base64编码的字串。

binaryData用得比较少，这里主要理解**data**字段。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: game-demo
data:
  # 经典的键值对方式存储
  player_initial_lives: "3"
  ui_properties_file_name: "user-interface.properties"

  # 以文件的方式存储键值对，其中game.properties是文件名，以|线分界。
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5    
  user-interface.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true 
```

Pod中的容器有4种方式引用congfigMap配置:

1. 在容器命令和参数内;
2. 容器的环境变量;
3. 以卷的方式挂载;
4. 编写代码在 Pod 中运行，使用 Kubernetes API 来读取 ConfigMap;

> [!NOTE]
> 官方有说明 ConfigMap 在设计上不是用来保存大量数据的。在 ConfigMap 中保存的数据不可超过 1 MiB。

