# GuGu Flutter 项目 — 本机开发环境变量（每次新开终端可先执行: . .\scripts\setup-env.ps1）
$javaHome = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$sdkRoot  = "$env:LOCALAPPDATA\Android\Sdk"
$flutter  = "D:\flutter\bin"
$git      = "C:\Program Files\Git\bin"

$env:JAVA_HOME        = $javaHome
$env:ANDROID_HOME     = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:PUB_CACHE        = "D:\pub-cache"
$env:PATH = "$flutter;$git;$javaHome\bin;$sdkRoot\platform-tools;$sdkRoot\cmdline-tools\latest\bin;" + $env:PATH

Write-Host "Flutter: $(flutter --version 2>&1 | Select-Object -First 1)" -ForegroundColor Green
flutter doctor
