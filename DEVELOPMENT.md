# 回响 (Echo) 开发环境配置

本文档记录项目所需的完整开发工具链版本，确保在 Windows 和 macOS 上都能一致构建。

## 系统要求

- **Windows**: Windows 10 或更高版本
- **macOS**: macOS 12 (Monterey) 或更高版本

---

## 工具链版本

### 1. Flutter SDK
- **版本**: 3.27.1
- **渠道**: stable
- **下载地址**: https://docs.flutter.dev/release/archive
- **安装路径建议**:
  - Windows: `C:\flutter` 或 `D:\flutter`
  - macOS: `~/flutter`

**验证命令**:
```bash
flutter --version
# 应显示: Flutter 3.27.1 • channel stable
```

### 2. Dart SDK
- **版本**: 随 Flutter 一起安装（Flutter 3.27.1 对应 Dart 3.6.0）
- **无需单独安装**

**验证命令**:
```bash
dart --version
# 应显示: Dart SDK version: 3.6.0
```

### 3. Android SDK
- **Android SDK Platform**: API 36 (Android 16)
- **Android SDK Build-Tools**: 34.0.0
- **Android SDK Command Line Tools**: 最新版
- **Android Emulator**: 可选，用于测试

**安装方式**:
- 通过 Android Studio 的 SDK Manager 安装
- 或使用 `sdkmanager` 命令行工具

**验证命令**:
```bash
sdkmanager --list_installed | grep "platforms;android-36"
sdkmanager --list_installed | grep "build-tools;34.0.0"
```

### 4. Android NDK
- **版本**: 28.2.13676358
- **安装路径**: 通过 Android Studio SDK Manager 安装

**验证**:
- 在 Android Studio 中: Tools → SDK Manager → SDK Tools → NDK (Side by side)

### 5. Gradle
- **版本**: 8.14
- **无需单独安装**，使用项目自带的 Gradle Wrapper

**验证命令**:
```bash
cd android
./gradlew --version  # macOS/Linux
.\gradlew --version  # Windows
# 应显示: Gradle 8.14
```

### 6. JDK (Java Development Kit)
- **版本**: 17 (Oracle JDK 或 OpenJDK)
- **推荐**: Eclipse Temurin (Adoptium) OpenJDK 17

**下载地址**:
- https://adoptium.net/temurin/releases/?version=17

**验证命令**:
```bash
java --version
# 应显示: openjdk 17.0.x
```

**环境变量配置**:
- `JAVA_HOME` 指向 JDK 安装目录
- `PATH` 包含 `%JAVA_HOME%\bin` (Windows) 或 `$JAVA_HOME/bin` (macOS)

### 7. Kotlin
- **版本**: 2.1.0
- **无需单独安装**，由 Gradle 自动管理

---

## 环境变量配置

### Windows

```powershell
# 用户环境变量
[Environment]::SetEnvironmentVariable("FLUTTER_HOME", "D:\flutter", "User")
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-17", "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", "D:\GradleCache\.gradle", "User")

# 更新 PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
$path += ";%FLUTTER_HOME%\bin;%JAVA_HOME%\bin;%ANDROID_HOME\platform-tools"
[Environment]::SetEnvironmentVariable("PATH", $path, "User")
```

### macOS

编辑 `~/.zshrc` 或 `~/.bash_profile`:

```bash
# Flutter
export FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

# Java
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

# Gradle 缓存
export GRADLE_USER_HOME="$HOME/.gradle"
```

---

## 项目构建步骤

### 首次构建

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd echo_app
   ```

2. **验证环境**
   ```bash
   flutter doctor
   # 确保所有打勾的项目都通过
   ```

3. **获取依赖**
   ```bash
   flutter pub get
   ```

4. **构建项目**
   ```bash
   flutter run
   ```

### 日常开发

```bash
# 检查环境
flutter doctor

# 获取依赖（当 pubspec.yaml 变更后）
flutter pub get

# 运行项目
flutter run

# 构建 Release 版本
flutter build apk --release        # Android
flutter build ios --release        # iOS (macOS only)
```

---

## 常见问题

### 1. Gradle 编译守护进程崩溃

**解决方案**:
```bash
# 停止所有 Java 进程
# Windows: 任务管理器结束 java.exe
# macOS: killall java

# 清理构建缓存
flutter clean
cd android && ./gradlew clean && cd ..
flutter run
```

### 2. 依赖版本冲突

**解决方案**:
```bash
flutter pub upgrade
flutter clean
flutter run
```

### 3. Android SDK 版本不匹配

**解决方案**:
- 打开 Android Studio
- Tools → SDK Manager
- 安装 API 36 (Android 16) 和 Build-Tools 34.0.0

### 4. Kotlin 守护进程问题

在 `android/gradle.properties` 中已配置:
```properties
kotlin.incremental=false
kotlin.compiler.allWarningsAsErrors=false
org.gradle.jvmargs=-Xmx4g
kotlin.daemon.jvm.options=-Xmx2g
```

---

## 版本升级指南

当需要升级工具链版本时:

1. 在 **本机** 测试新版本
2. 更新本文档中的版本号
3. 提交文档到 Git
4. 通知团队成员同步更新

---

## 参考链接

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Android Studio 下载](https://developer.android.com/studio)
- [Eclipse Temurin JDK](https://adoptium.net/)
- [Gradle 官方文档](https://docs.gradle.org/)

---

**最后更新**: 2026年4月
