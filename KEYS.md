# 回响 (Echo) 项目关键配置汇总

本文档汇总前后端所有需要配置的关键密钥和参数，方便部署和迁移时查阅。
**注意：本文档只记录配置项名称和用途，不包含实际密钥值。**

---

## SSH 登录密钥

| Key 名称 | 类型 | 存储位置 | 配置位置 | 用途 |
|----------|------|----------|----------|------|
| `id_ed25519_tencent` | SSH Ed25519 密钥对 | 本地: `C:\Users\MateBook\.ssh\` | 服务器 `/root/.ssh/authorized_keys` + `/home/deploy/.ssh/authorized_keys` | 本地 SSH 登录腾讯云服务器 |

### GitHub Actions 部署密钥

| Key 名称 | 类型 | 存储位置 | 配置位置 | 用途 |
|----------|------|----------|----------|------|
| `DEPLOY_KEY` | SSH 私钥（同 id_ed25519_tencent 私钥） | GitHub Secrets（echo-backend 仓库） | 仓库 Settings → Secrets → Actions | Actions 工作流 SSH 登录服务器执行部署 |

---

## 后端关键配置 (echo_backend/.env)

| 序号 | 配置项 | 用途 | 获取方式 |
|------|--------|------|----------|
| 1 | `DATABASE_URL` | PostgreSQL 数据库连接字符串 | Supabase/Neon 控制台 |
| 2 | `JWT_SECRET` | JWT 签名密钥，用于用户认证 | 自行生成随机字符串 |
| 3 | `AI_PROVIDER` | AI 服务提供商选择 (deepseek/openai/qwen) | 根据使用的服务填写 |
| 4 | `DEEPSEEK_API_KEY` | DeepSeek API 密钥 | DeepSeek 开放平台 |
| 5 | `OPENAI_API_KEY` | OpenAI API 密钥 (备用) | OpenAI 平台 |
| 6 | `QWEN_API_KEY` | 通义千问 API 密钥 (备用) | 阿里云百炼平台 |
| 7 | `NEXT_PUBLIC_API_BASE_URL` | 后端公网 API 地址 | 部署后域名或 IP |
| 8 | `UPLOAD_SECRET` | APK 上传接口校验密钥 | 自行生成随机字符串 |
| 9 | `PORT` | 服务端口号 | 默认 3001 |

### 后端配置注意事项

- **DATABASE_URL**：国内服务器推荐使用 Supabase Session Pooler (port 5432, IPv4)
- **JWT_SECRET**：生产环境务必使用强随机字符串，不要硬编码
- **AI_PROVIDER**：切换 AI 提供商只需改此配置，无需修改代码
- 密码含特殊字符时需 URL encode：`node -e "console.log(encodeURIComponent('密码'))"`

---

## 前端关键配置 (echo_app)

| 序号 | 配置项 | 用途 | 配置位置 |
|------|--------|------|----------|
| 1 | `API_BASE_URL` | 后端 API 基础地址 | `lib/config/app_config.dart` 或 `--dart-define` |

### 前端配置方式

**方式一：硬编码（开发环境）**
编辑 `lib/config/app_config.dart`：
```dart
static String get apiBaseUrl => 'https://api.wudiclaw.cloud/api';
```

**方式二：编译时注入（推荐，生产环境）**
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-api.com/api
```

---

## 前端构建相关密钥 (echo_app)

| 序号 | 配置项 | 用途 | 当前状态 | 备注 |
|------|--------|------|----------|------|
| 1 | **Android Keystore** | APK/AAB 发布签名 | 未配置（使用 debug 签名） | 正式上架应用商店必须配置 release 签名 |
| 2 | **Keystore 密码** | 签名密钥保护 | 未配置 | 与 Keystore 配套使用 |
| 3 | **Key Alias** | 密钥别名 | 未配置 | 与 Keystore 配套使用 |
| 4 | **versionCode** | Android 版本号（整数） | `1` | 每次发布需递增 |
| 5 | **versionName** | 应用版本名称 | `1.0.0` | 对应 Git tag v1.0.0 |

### Android Release 签名配置步骤

1. 生成 Keystore：
   ```bash
   keytool -genkey -v -keystore echo-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias echo
   ```
2. 放置到 `android/app/echo-key.jks`
3. 创建 `android/key.properties`：
   ```properties
   storePassword=你的密码
   keyPassword=你的密码
   keyAlias=echo
   storeFile=echo-key.jks
   ```
4. 修改 `android/app/build.gradle.kts` 的 `signingConfig`

---

## 服务器部署关键信息

| 配置项 | 用途 | 备注 |
|--------|------|------|
| 服务器公网 IP | 前端连接后端 | 腾讯云控制台查看 |
| 域名 + SSL 证书 | HTTPS 访问 | 可选，Nginx 反代配置 |
| 防火墙/安全组 | 放行 3000/3001 端口 | 腾讯云安全组入站规则 |
| pm2 进程管理 | 后端保活运行 | `pm2 start server.js` |

---

## 第三方平台账号

| 平台 | 用途 | 备注 |
|------|------|------|
| GitHub | 代码托管 + 自动部署 | webhook 触发服务器部署 |
| Supabase | PostgreSQL 数据库 | 免费版已够用 |
| DeepSeek | AI 对话能力 | 国内访问稳定 |
| 腾讯云 | 服务器 + EdgeOne | 2C4G 服务器 |

---

**最后更新**: 2026-05-01
