# 回响 (Echo) 项目关键配置汇总

## 链路 1：本地 Windows → GitHub

| 属性 | 值 |
|------|-----|
| Key 名称 | `id_ed25519` |
| Key 类型 | SSH Ed25519 密钥对 |
| 公钥内容 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIErlHcu5TamKZA/S65XfzCcY8JmjW/TSrks976JHgMRp 78193390@qq.com` |
| 私钥 | 敏感，不展示 |
| 存储位置 | `C:\Users\MateBook\.ssh\` |
| 配置位置 | GitHub 账户 Settings → SSH and GPG keys |
| 用途 | 本地 git push/pull 代码 |

---

## 链路 2：腾讯云 → GitHub

| 属性 | 值 |
|------|-----|
| Key 名称 | `id_github`（deploy 用户） |
| Key 类型 | SSH Ed25519 密钥对 |
| 公钥内容 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+aYJsQr9luPU6/JVIGfHZhpwX74ynW3fxwh3hM7ZsQ deploy@tencent` |
| 私钥 | 敏感，不展示 |
| 存储位置 | `/root/.ssh/` 和 `/home/deploy/.ssh/` |
| 配置位置 | GitHub 账户 Settings → SSH and GPG keys |
| 用途 | 服务器 git pull 拉代码 |

---

## 链路 3：本地 Windows → 腾讯云

| 属性 | 值 |
|------|-----|
| Key 名称 | `id_ed25519_tencent` |
| Key 类型 | SSH Ed25519 密钥对 |
| 公钥内容 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGX5VODrtgtU17ZhDEd295zle96jkBbXze92RrcmmwmJ tencent-deploy` |
| 私钥 | 敏感，不展示 |
| 存储位置 | `C:\Users\MateBook\.ssh\` |
| 配置位置 | 服务器 `/root/.ssh/authorized_keys` + `/home/deploy/.ssh/authorized_keys` |
| 用途 | 本地 SSH 登录服务器 |

---

## 链路 4：GitHub Actions → 腾讯云

| 属性 | 值 |
|------|-----|
| Key 名称 | `DEPLOY_KEY` |
| Key 类型 | SSH 私钥 |
| Key 内容 | 同 `id_ed25519_tencent` 私钥内容 |
| 存储位置 | GitHub Secrets（echo-backend 仓库） |
| 配置位置 | 仓库 Settings → Secrets and variables → Actions |
| 用途 | Actions 工作流 SSH 登录服务器执行部署 |

---

## 链路 5：本地 MacBook → GitHub

| 属性 | 值 |
|------|-----|
| Key 名称 | `id_ed25519` |
| Key 类型 | SSH Ed25519 密钥对 |
| 公钥内容 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/kpkDW7U8gEt2cX/SBHHwbp3H2fwZmIoUgIGQnsfKV 78193390@qq.com` |
| 私钥 | 敏感，不展示 |
| 存储位置 | `/Users/leo/.ssh/` |
| 配置位置 | GitHub 账户 Settings → SSH and GPG keys |
| 用途 | 本地 git push/pull 代码 |
| SSH 配置文件 | `/Users/leo/.ssh/config` |

---

## 链路 6：本地 iMac → GitHub

| 属性 | 值 |
|------|-----|
| Key 名称 | `id_ed25519` |
| Key 类型 | SSH Ed25519 密钥对 |
| 公钥内容 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOhhp33MfqIL44SLZNdzTWYCWoHzsiismTH5vOazTvr iMac2Github` |
| 私钥 | 敏感，不展示 |
| 存储位置 | `/Users/wing/.ssh/` |
| 配置位置 | GitHub 账户 Settings → SSH and GPG keys |
| 用途 | 本地 git push/pull 代码 |

---

## 链路 7：本地 MacBook → 腾讯云

| 属性 | 值 |
|------|-----|
| Key 名称 | `id_ed25519_tencent` |
| Key 类型 | SSH Ed25519 密钥对 |
| 公钥内容 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGX5VODrtgtU17ZhDEd295zle96jkBbXze92RrcmmwmJ tencent-deploy` |
| 私钥 | 敏感，不展示 |
| 存储位置 | `/Users/leo/.ssh/` |
| 配置位置 | 服务器 `/home/deploy/.ssh/authorized_keys` + `/root/.ssh/authorized_keys` |
| 用途 | 本地 SSH 登录服务器 |
| SSH 配置文件 | `/Users/leo/.ssh/config` |
| 连接命令 | `ssh tencent` |
| 服务器地址 | `129.211.6.20` |
| 登录用户 | `deploy` |

---

**最后更新**: 2026-05-03
