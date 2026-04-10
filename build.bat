@echo off
chcp 65001 >nul
echo ========================================
echo     回响 App Flutter 构建脚本
echo ========================================
echo.

REM 设置环境变量
set ANDROID_HOME=D:\Android\Sdk
set PATH=%PATH%;D:\flutter\flutter\bin

REM 解析参数
if "%~1"=="clean" goto clean
if "%~1"=="rebuild" goto rebuild
if "%~1"=="debug" goto debug
if "%~1"=="install" goto install
if "%~1"=="help" goto help

REM 默认: 增量构建 Release
echo 执行增量构建 (Release)...
flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo 构建失败!
    exit /b 1
)
goto success

:clean
echo 执行清理...
flutter clean
if exist ".dart_tool" rd /s /q ".dart_tool"
if exist "build" rd /s /q "build"
flutter pub get
echo 清理完成!
goto end

:rebuild
echo 执行完整重建...
flutter clean
if exist ".dart_tool" rd /s /q ".dart_tool"
if exist "build" rd /s /q "build"
flutter pub get
flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo 构建失败!
    exit /b 1
)
goto success

:debug
echo 执行 Debug 构建...
flutter build apk --debug
if %ERRORLEVEL% neq 0 (
    echo 构建失败!
    exit /b 1
)
goto success

:install
echo 安装 APK 到设备...
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
if not exist %APK_PATH% set APK_PATH=build\app\outputs\flutter-apk\app-debug.apk
if not exist %APK_PATH% (
    echo 错误: 找不到 APK 文件
    exit /b 1
)
%ADB_HOME%\platform-tools\adb.exe install -r %APK_PATH%
if %ERRORLEVEL% neq 0 (
    echo 安装失败!
    exit /b 1
)
echo 安装成功!
goto end

:help
echo 用法: build.bat [命令]
echo.
echo 命令:
echo   (无)     执行增量构建 (Release)
echo   clean    清理构建缓存
echo   rebuild  完整重建 (清理 + 获取依赖 + 构建)
echo   debug    构建 Debug 版本
echo   install  安装 APK 到连接的设备
echo   help     显示帮助信息
echo.
goto end

:success
echo.
echo ========================================
echo     构建成功!
echo ========================================
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo APK 位置: build\app\outputs\flutter-apk\app-release.apk
    for %%I in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set size=%%~zI
    )
    echo APK 大小: %size% 字节
)
goto end

:end
echo.
pause
