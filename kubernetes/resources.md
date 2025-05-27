# 资源清单YAML语法字段

管理资源对象YAML文件的语法格式及字段。

## Pod资源

```yaml
apiVersion: v1
kind: Pod
metadata:
    namespace: default
    name: my-app
    labels:
        environment: devel
        app: nginx
    annotations:
        imageregistry: "https://hub.docker.com/"
spec:
    containers:
    - name: nginx
      image: nginx:1.14.0
      ports:
      - containerPort: 8080
```

