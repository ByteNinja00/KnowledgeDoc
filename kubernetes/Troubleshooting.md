# 故障排查

- *Retrying due to error: could not find a JWS signature in the cluster-info ConfigMap for token ID "gqykn8"*

通常出现在使用 kubeadm join 命令将节点加入 Kubernetes 集群时。这意味着 token 的对应签名信息没有在 kube-public namespace 的 cluster-info ConfigMap 中找到，需要重新生成一个新的token:

```bash
kubeadm token create --print-join-command
```

- Secret "kubeadm-certs" was not found in the "kube-system" Namespace. This Secret might have expired. Please, run `kubeadm init phase upload-certs --upload-certs` on a control plane to generate a new one

节点加入时证书失效，需要更新证书：

```bash
kubeadm init phase upload-certs --upload-certs
```

