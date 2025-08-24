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

**恢复污点之前的状态**:

之前执行`kubectl drain`drain 默认会给节点打 Unschedulable 标记（相当于 kubectl cordon），所有节点不可调度，需要直接取消cordon。

```bash
kubectl get nodes --no-headers |awk '{print $1}'|while read line;do kubectl uncordon $line; done
```
