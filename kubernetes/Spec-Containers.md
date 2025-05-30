# Containers

用于描述 Pod 中运行的一个或多个容器的详细配置。

**字段列表：**

|字段|类型|描述|
|----|----|----|
|args| []string|传递给 command 的参数|
|command| \[]string| 容器启动时的命令（替代镜像默认 CMD）|
|env| \[]EnvVar| 环境变量设置|
|envFrom| \[]EnvFromSource|从 ConfigMap 或 Secret 批量导入环境变量的字段|
|image|string|使用的容器镜像，例如 nginx:1.21|
|imagePullPolicy|string|镜像拉取策略（Always、IfNotPresent 等）|
|lifecycle|Lifecycle|在容器启动或终止之前/之后执行自定义逻辑|
|livenessProbe|Probe|容器存活探测|
|name|string|容器名称|
|ports|\[]ContainerPort|容器暴露的端口（如 HTTP 端口等）|
|readinessProbe|Probe|容器就绪探测|
|resizePolicy|\[]ContainerResizePolicy|用于控制容器级别的资源调整策略。|
|resources|ResourceRequirements|CPU/内存的资源请求和限制|
|restartPolicy|string|容器重启策略|
|securityContext|SecurityContext|安全上下文（如运行用户、权限等）|
|startupProbe|Probe|容器启动探测|
|stdin|boolean|是否保持标准输入通道打开。|
|stdinOnce|boolean|如果为 true，标准输入只对第一个连接者可用，之后关闭。|
|terminationMessagePath|string|ll|
|terminationMessagePolicy|string|ll|
|tty|boolean|是否为容器分配一个伪终端（tty），用于交互式应用。|
|volumeDevices|[]VolumeDevice|ll|
|volumeMounts|[]VolumeMount|把 Pod 的卷挂载到容器内路径|
|workingDir|string|ll|

## args

pod.spec.containers 中，args 字段用于为容器启动命令（command）提供参数，作用类似于 Linux 中运行命令时跟在后面的参数。

args ➜ 覆盖镜像的 CMD

```yaml
spec:
  containers:
    - name: demo
      image: busybox
      command: ["sh"]
      args: ["-c", "echo Hello from Kubernetes && sleep 3600"]
```

## command

command 字段用于覆盖容器镜像的默认启动命令（Dockerfile 中的 ENTRYPOINT）。它指定容器启动时要执行的程序或脚本。

## env

spec.containers[].env 字段用于为容器内的进程设置环境变量，相当于在容器内执行前设置的 export VAR=value。

```yaml
spec:
  containers:
    - name: app
      image: nginx
      env:
        - name: ENV_MODE
          value: "production"
        - name: PORT
          value: "8080"
```

## envFrom

envFrom 是 Kubernetes 中用来一次性从 ConfigMap 或 Secret 批量导入环境变量的字段，比 env 更简洁适用于多变量注入场景。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  containers:
    - name: app
      image: nginx
      envFrom:
        - configMapRef:
            name: my-config
          prefix: "CFG_"
        - secretRef:
            name: my-secret
```

## image

image 是容器最核心的字段之一，用于指定容器运行时所使用的镜像。镜像是容器的操作系统、应用程序和依赖的打包集合，本质上就是“运行容器的源”。

```yaml
spec:
  containers:
    - name: myapp
      image: nginx:1.25.3
```

## imagePullPolicy

镜像拉取策略（Always、IfNotPresent 等）。

## lifecycle

在 Kubernetes 中，lifecycle 是用来定义**容器生命周期钩子函数（Hooks）**的字段，它允许你在容器启动或终止之前/之后执行自定义逻辑，常用于：

容器启动初始化逻辑

优雅终止清理操作

注册/注销服务实例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-demo
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "echo running && sleep 300"]
      lifecycle:
        postStart:
          exec:
            command: ["sh", "-c", "echo 容器启动后初始化..."]
        preStop:
          exec:
            command: ["sh", "-c", "echo 容器将要终止，准备清理... && sleep 10"]
```

## livenessProbe

容器运行期间存活探测，存活失败依据重启策略重启容器。[参考容器探针](/kubernetes/probe.md)

## name

容器名

## ports

pod.spec.containers.ports 是 Pod 配置文件中用于定义容器暴露的端口的字段

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: web-container
    image: nginx:latest
    ports:
    - name: http
      containerPort: 80
      protocol: TCP
    - name: https
      containerPort: 443
      protocol: TCP
```

## readinessProbe

[参考容器探针](/kubernetes/probe.md)

## resizePolicy

定义容器在运行时如何处理资源（如 CPU 和内存）的动态调整行为。

```yaml
spec:
  containers:
  - name: <container-name>
    image: <image>
    resizePolicy:
    - resourceName: <string>  # 资源名称（cpu 或 memory）
      restartPolicy: <string> # 调整时的重启策略
```

- resourceName: 指定调整的资源类型：
  - cpu: 处理器资源（如 500m）。
  - memory: 内存资源（如 512Mi）。
- restartPolicy: 定义资源调整时的行为：
  - NotRequired: 资源调整无需重启容器，实时生效（需应用支持动态调整）。
  - RestartContainer: 调整资源后重启容器（默认，适用于大多数场景）。
  - RestartPod: 调整资源后重启整个 Pod（较少使用）。

## resources

用于定义 Pod 中容器资源需求的字段，主要用于指定容器所需的计算资源（如 CPU 和内存）的请求（requests）和限制（limits）。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: example-container
    image: nginx
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

- resources 字段结构:
  - requests: 指定容器运行所需的最小资源量。
  - limits: 指定容器使用的最大资源量。

## restartPolicy

可选值：

- Always（默认）：不管容器退出的原因是什么，kubelet 总是会重启容器。适用于 Deployment、ReplicaSet 等控制器管理的 Pod。

- OnFailure：只有当容器以非 0 状态退出时，kubelet 才会重启容器。常用于 Job 资源。

- Never：容器退出后不会被重启。适合调试或一次性任务的 Pod。

> [!TIP]
> 可能官方文档有错误，restartPolicy在pod.spec下。

## securityContext

这个字段定义了 Pod 级别的安全策略，影响 Pod 内所有容器的默认行为（当然，容器可以通过 securityContext 覆盖）。

pod.spec.containers.securityContext 是 Kubernetes 中用于配置容器级别安全策略的重要字段。它允许你控制容器进程的权限、用户身份、是否允许以 root 运行等安全设置。

这是容器自己的安全上下文，会覆盖 Pod 级别的 pod.spec.securityContext 设置（即“谁离得近，谁说了算”）。

| 字段名                        | 类型               | 说明                                                           |
| -------------------------- | ---------------- | ------------------------------------------------------------ |
| `allowPrivilegeEscalation` | `bool`           | 是否允许进程通过提权（如 `setuid`）获取更高权限。建议设为 `false`，提高安全性。             |
| `privileged`               | `bool`           | 是否启用特权模式。设置为 `true`，容器几乎拥有主机全部权限（⚠️ 高危）。                     |
| `capabilities`             | `Capabilities`   | 控制添加或移除 Linux capabilities，比如 `NET_ADMIN`, `SYS_TIME`。       |
| `readOnlyRootFilesystem`   | `bool`           | 是否将根文件系统挂载为只读。安全实践推荐设为 `true`。                               |
| `runAsUser`                | `int64`          | 指定容器进程以哪个 UID 运行。覆盖 Pod 级别配置。                                |
| `runAsGroup`               | `int64`          | 指定容器进程以哪个 GID 运行。                                            |
| `runAsNonRoot`             | `bool`           | 要求以非 root 用户运行。                                              |
| `seLinuxOptions`           | `SELinuxOptions` | 配置 SELinux 标签，适用于启用了 SELinux 的系统。                            |
| `seccompProfile`           | `SeccompProfile` | 配置 seccomp 限制（比如 `RuntimeDefault`、`Unconfined`、自定义 profile）。 |
| `procMount`                | `string`         | 设置 `/proc` 的挂载类型（默认 `Default`，另有 `Unmasked`，⚠️ 高危）。          |

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-container
spec:
  containers:
  - name: myapp
    image: busybox
    command: ["sleep", "3600"]
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

✅ 这个配置做了什么？

- 使用 UID 和 GID 为 1000 启动容器；

- 强制不以 root 启动；

- 禁止提权；

- 根文件系统设为只读；

- 移除了所有 Linux 能力（capabilities），达到最小权限原则。

## startupProbe

[参考容器探针](/kubernetes/probe.md)

## stdin

设置 stdin: true 表示 即使容器没有连接终端，也会为其保留一个标准输入通道。这在以下场景有用：

✅ 运行需要交互的命令（如：cat、某些 CLI 工具）；

✅ 配合 kubectl exec 进入容器后交互使用；

✅ 配合 stdinOnce: true 只接受第一次连接的输入。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: interactive-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["/bin/sh"]
    tty: true
    stdin: true
```