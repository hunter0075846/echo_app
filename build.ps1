# 回响 App Flutter 构建脚本
param([string]$Command="",[string]$ApiUrl="")
$ProjectRoot=Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot
$env:ANDROID_HOME="D:\Android\Sdk"
$env:PATH="$env:PATH;D:\flutter\flutter\bin"
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
function WG($msg){Write-Host $msg -ForegroundColor Green}
function WR($msg){Write-Host $msg -ForegroundColor Red}
function WY($msg){Write-Host $msg -ForegroundColor Yellow}
function WC($msg){Write-Host $msg -ForegroundColor Cyan}
WC "========================================"
WC "    回响 App Flutter 构建脚本"
WC "========================================"
Write-Host ""
WY "当前镜像配置:"
Write-Host "  PUB_HOSTED_URL: $env:PUB_HOSTED_URL"
Write-Host "  FLUTTER_STORAGE_BASE_URL: $env:FLUTTER_STORAGE_BASE_URL"
Write-Host ""
$dartDefines=""
if($ApiUrl -ne ""){
    WY "使用自定义 API 地址: $ApiUrl"
    $dartDefines="--dart-define=API_BASE_URL=$ApiUrl"
}else{
    WY "使用默认 API 地址"
}
Write-Host ""
$flutterBat="D:\flutter\flutter\bin\flutter.bat"
if(-not(Test-Path $flutterBat)){WR "错误: 找不到 Flutter";exit 1}
if($Command -eq "clean"){
    WY "执行清理..."
    & $flutterBat clean
    Remove-Item -Recurse -Force "$ProjectRoot\.dart_tool" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$ProjectRoot\build" -ErrorAction SilentlyContinue
    WG "清理完成!"
}elseif($Command -eq "rebuild"){
    WY "执行完整重建..."
    & $flutterBat clean
    Remove-Item -Recurse -Force "$ProjectRoot\.dart_tool" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$ProjectRoot\pubspec.lock" -ErrorAction SilentlyContinue
    WY "获取依赖..."
    & $flutterBat pub get
    if($LASTEXITCODE -ne 0){WR "获取依赖失败!";exit 1}
    WY "构建 APK..."
    if($dartDefines -ne ""){& $flutterBat build apk --release $dartDefines}else{& $flutterBat build apk --release}
    if($LASTEXITCODE -eq 0){WG "构建成功!"}else{WR "构建失败!"}
}elseif($Command -eq "debug"){
    WC "执行 Debug 构建..."
    if($dartDefines -ne ""){& $flutterBat build apk --debug $dartDefines}else{& $flutterBat build apk --debug}
    if($LASTEXITCODE -eq 0){WG "构建成功!"}else{WR "构建失败!"}
}elseif($Command -eq "install"){
    WC "安装 APK..."
    $apk="$ProjectRoot\build\app\outputs\flutter-apk\app-release.apk"
    if(-not(Test-Path $apk)){$apk="$ProjectRoot\build\app\outputs\flutter-apk\app-debug.apk"}
    if(-not(Test-Path $apk)){WR "错误: 找不到 APK 文件";exit 1}
    $adb="$env:ANDROID_HOME\platform-tools\adb.exe"
    & $adb install -r "$apk"
    if($LASTEXITCODE -eq 0){WG "安装成功!"}else{WR "安装失败!"}
}else{
    WC "执行增量构建..."
    if($dartDefines -ne ""){& $flutterBat build apk --release $dartDefines}else{& $flutterBat build apk --release}
    if($LASTEXITCODE -eq 0){WG "构建成功!";$apk="$ProjectRoot\build\app\outputs\flutter-apk\app-release.apk";if(Test-Path $apk){$size=(Get-Item $apk).Length/1MB;WC "APK 大小: $([math]::Round($size,2)) MB"}}else{WR "构建失败!"}
}
Write-Host ""
WC "========================================"
