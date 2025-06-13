# 调度亲和性

调度亲和性是指：用来在调度阶段表达「把 Pod 放到哪里（或不放到哪里）」的策略。它包含三大块：

1. **Node Affinity（节点亲和性）**
2. **Pod Affinity（Pod 亲和性）**
3. **Pod Anti‑Affinity（Pod 反亲和性）**

## 一、Node Affinity（节点亲和性）

根据匹配节点条件来选择调度亲和性，分为软亲和性和硬亲和性。

### 软亲和性

