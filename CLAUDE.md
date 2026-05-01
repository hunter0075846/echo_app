## 项目授权

本项目（echo_app）已授权 Claude Code 全权自主执行以下操作，无需每次询问：

- git push、git pull、git tag
- gh CLI 命令（gh run、gh pr 等）
- flutter build、flutter pub get
- 修改 .github/workflows/ CI/CD 配置
- 编辑项目配置文件

**约束：**
- 不执行 `git push --force` 或 `git reset --hard`
- 密钥值不进日志、不进输出
