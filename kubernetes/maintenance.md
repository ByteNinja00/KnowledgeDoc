# 集群维护指南

本页涵盖Kubernetes集群维护相关操作。

## 删除集群中己有的CNI插件(Calico)

有一次布署完集群calico网络插件之后，calico节点一直处于Peding状态，回想一下可能是因为多网卡环境下，没有让calico绑定指定网卡，想验证一下是否是这个原因，所以通过`kubectl delete -f calico.yaml`直接删除。

就是因为这个操作导致 `error killing pod: failed to "KillPodSandbox" for "6c3bc0f9-149f-4c5d-97cc-6aba7e65e917" with KillPodSandboxError: "rpc error: code = Unknown desc = failed to destroy network for sandbox \"8008514e7b4b1872b96d94aa52b1eee029ef9aaa96f38cfa1feb8012cda5550f\": plugin type=\"calico\" failed (delete): error getting ClusterInformation: connection is unauthorized: Unauthorized"`，原因是：直接删除了 Calico 的 YAML（CRD、Controller、DaemonSet），但是节点上还有 Pod 在尝试调用 Calico CNI 去清理网络。CNI 插件需要访问 Calico 的 ClusterInformation CRD，但这个 CRD 已经被删掉或 API 权限丢失，于是出现了 Unauthorized。

- Calico 的 CNI 插件（安装在每个节点上 /opt/cni/bin/calico）执行 Pod 创建/删除 时，会去访问 Kubernetes 的 Calico CRD（例如 ClusterInformation）。
- 当你把 Calico CRD / Controller 删除后，CNI 插件仍然尝试清理 Pod 网络，但 API 已不可用，于是报错。
- 这类情况常见于 直接 kubectl delete -f calico.yaml 卸载 Calico，导致节点清理 Pod sandbox 时失败。

**解决办法**:

- 先清空 Pod, 把业务 Pod 驱逐掉，保证节点上没有 workload 需要依赖 Calico 网络：

```bash
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

- 删除 Calico 组件（Controller/DaemonSet 等）：

```bash
kubectl delete -f calico.yaml
```

- 确认 CRD 和 CNI 配置也删除：
  - 删除 CRD：

    ```bash
    kubectl delete crd bgpconfigurations.crd.projectcalico.org \
    bgppeers.crd.projectcalico.org \
    felixconfigurations.crd.projectcalico.org \
    ippools.crd.projectcalico.org \
    hostendpoints.crd.projectcalico.org \
    clusterinformations.crd.projectcalico.org
    ```

    - 删除节点上的 CNI 配置文件和二进制：

    ```bash
    rm -f /etc/cni/net.d/10-calico.conflist
    rm -f /opt/cni/bin/calico /opt/cni/bin/calico-ipam
    ```

- 清理残留的sandbox pod：

```bash
for s in `sudo crictl pods -q`; do sudo crictl stopp $s; sudo crictl rmp $s; done
```

**恢复污点之前的状态**:

之前执行`kubectl drain`drain 默认会给节点打 Unschedulable 标记（相当于 kubectl cordon），所有节点不可调度，需要直接取消cordon。

```bash
kubectl get nodes --no-headers |awk '{print $1}'|while read line;do kubectl uncordon $line; done
```

## Calico网络插件绑定网卡

在我的k8s集群里一般都使用官方源站的容器镜像，当然国内也有镜像站点比如阿里云的，这里的背景主要是我的集群全程使用科学上网的方式拉取镜像，所以每台主机都布署了`sing-box`网络代理工具。
这就导致了我的主机上有两张网卡，Calico 默认会选择系统的默认路由网卡。如果主机默认路由的网卡是sing-box的tunl虚拟网卡，那么会导致布署calico容器时一直处理back-off状态。

- **如果己经布署修改`ConfigMap`**:

```bash
kubectl edit configmap -n kube-system calico-config
```

找到 calico-node 的环境变量配置，一般在 DaemonSet calico-node 里，主要修改以下字段：

```bash
- name: IP_AUTODETECTION_METHOD
  value: "interface=eth1"
```

- **如果还没部署在下载的官方安装清单（YAML 文件）里直接加上 IP_AUTODETECTION_METHOD 配置，这样部署后就会生效，不需要再改。**

打开下载的 calico.yaml，找到 DaemonSet calico-node 部分,在 env: 里加上你要绑定的网卡（比如 eth1）：

```bash
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: calico-node
  namespace: kube-system
spec:
  template:
    spec:
      containers:
        - name: calico-node
          env:
            - name: DATASTORE_TYPE
              value: "kubernetes"
            - name: CALICO_NETWORKING_BACKEND
              value: "bird"
            # 这里添加一行
            - name: IP_AUTODETECTION_METHOD
              value: "interface=eth1"
```
