# configMap对象

configMap存储让其它对象可引用其配置的API对象。有两个字段**data**和**binaryData**。

- data：用来保存UTF-8字符串。
- binaryData：用来保存二进制数据作为base64编码的字串。

binaryData用得比较少，这里主要理解**data**字段。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-demo
  namespace: demo
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

## 实例

- 以环境变量的方式引用：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-demo
  namespace: demo
data:
  player_initial_lives: "3"
  ui_properties_file_name: "user-interface.properties"
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5    
  user-interface.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true 
---
apiVersion: v1
kind: Pod
metadata:
  name: cm-demo-pod
  namespace: demo
spec:
  containers: 
    - name: cm-demo-container
      image: alpine
      imagePullPolicy: IfNotPresent
      command: ["env"]
      env:
        - name: PLAYER_INITIAL_LIVES # 设置环境变量名
          valueFrom:
            configMapKeyRef:
              name: cm-demo # 这里是configMap名字的引用
              key: player_initial_lives # 获取该键的值并赋值给变量PLAYER_INITIAL_LIVES
        - name: UI_PROPERTIES_FILE_NAME
          valueFrom:
            configMapKeyRef:
              name: cm-demo
              key: ui_properties_file_name
```

> 执行 `kubectl apply -f cm-demo.yaml`; 查看容器日志：`kubectl logs -n demo pods/cm-demo-pod cm-demo-container` 在环境变量输出终端中将看到引用cm键的值。

- 以卷的方式挂载到容器里：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-demo
  namespace: demo
data:
  player_initial_lives: "3"
  ui_properties_file_name: "user-interface.properties"
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5    
  user-interface.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true
---
apiVersion: v1
kind: Pod
metadata:
  name: cm-demo-pod
  namespace: demo
spec:
  containers: 
    - name: cm-demo-container
      image: alpine
      imagePullPolicy: IfNotPresent
      command: ["ls"]
      args: ["/config"]
      volumeMounts:
        - name: config
          mountPath: "/config"
          readOnly: true
  volumes:
    - name: config
      configMap: 
        name: cm-demo
        items:
          - key: "game.properties"
            path: "game.properties"
          - key: "user-interface.properties"
            path: "user-interface.properties"
```

> [!WARNING]
> 在*cm-demo*的configMap中有四个键，如果不指定*items.key*和*items.path*将会挂载四个文件即：`player_initial_lives`, `ui_properties_file_name`, `game.properties`, `user-interface.properties`, 指定items去过滤要挂载的配置。

最后: `kubectl apply -f cm-demo.yaml`，执行: `kubectl logs -n demo pods/cm-demo-pod cm-demo-container` 查看 **/config** 目录下是否挂载 `game.properties`, `user-interface.properties`两个文件，并打开文件查看存储的值。