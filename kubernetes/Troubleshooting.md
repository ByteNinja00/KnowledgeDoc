# 故障排查

集群安装或管理过程中出现的报错提示及解决方法。

## 令牌(token)错误或过期

- *Retrying due to error: could not find a JWS signature in the cluster-info ConfigMap for token ID "gqykn8"*

通常出现在使用 kubeadm join 命令将节点加入 Kubernetes 集群时。这意味着 token 的对应签名信息没有在 kube-public namespace 的 cluster-info ConfigMap 中找到，需要重新生成一个新的token:

```bash
sudo kubeadm token create --print-join-command
```

## 集群通信证书过期

- Secret "kubeadm-certs" was not found in the "kube-system" Namespace. This Secret might have expired. Please, run `kubeadm init phase upload-certs --upload-certs` on a control plane to generate a new one

节点加入时证书失效，需要更新证书：

```bash
sudo kubeadm init phase upload-certs --upload-certs
```

## NFS网络共享目录挂载失败

- `Output: mount: /var/lib/kubelet/pods/f53a8187-fe38-40a4-bff0-a293ff832230/volumes/kubernetes.io~nfs/nfs-pv: bad option; for several filesystems (e.g. nfs, cifs) you might need a /sbin/mount.<type> helper program.`

 Kubernetes 的 kubelet 想通过 mount -t nfs 命令挂载 NFS 共享目录，但失败了，原因是系统缺少挂载 nfs 所需的工具程序。也就是说kubelet所在的宿主机上没有安装NFS相应的客户端工具。

```bash
sudo apt-get update && sudo apt-get -y install nfs-common
```

