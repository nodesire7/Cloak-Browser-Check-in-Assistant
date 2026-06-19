@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Cloak Browser 自动签到助手

cd /d "%~dp0"

echo.
echo  ╔══════════════════════════════════════════╗
echo  ║  Cloak Browser 自动签到助手              ║
echo  ║  Cloak Browser Check-in Assistant        ║
echo  ╚══════════════════════════════════════════╝
echo.

:: ── 解析参数 ──────────────────────────────────────────────────────────────────
set MODE=checkin
set SITE_ARG=
if "%~1"=="--setup" set MODE=setup
if "%~1"=="--login" set MODE=login
if "%~1"=="--help"  goto :help
if "%~1"=="/?"      goto :help
if not "%~1"=="" (
    if not "%~1"=="--setup" if not "%~1"=="--login" (
        set SITE_ARG=%~1
    )
)
goto :step1

:help
echo 用法 / Usage: run.bat [--setup ^| --login ^| ^<站点名^>]
echo.
echo   (无参数)    首次打开配置向导，之后直接签到所有站点
echo   --setup     打开配置向导（添加/编辑/删除站点）
echo   --login     清除 cookies 并强制重新登录
echo   ^<站点名^>   只对单个站点签到（如 ourbits）
exit /b 0

:: ── 第1步：检测 Python ─────────────────────────────────────────────────────────
:step1
echo [第 1/3 步] 检测 Python...
set PYTHON=
python --version >nul 2>&1
if not errorlevel 1 (set PYTHON=python & goto :python_ok)
python3 --version >nul 2>&1
if not errorlevel 1 (set PYTHON=python3 & goto :python_ok)

echo [-] 未找到 Python 3.8+
echo.
echo     请从 https://www.python.org/downloads/ 下载安装。
echo     安装时请勾选 "Add Python to PATH" 选项。
echo.
pause
exit /b 1

:python_ok
for /f "tokens=*" %%V in ('%PYTHON% --version 2^>^&1') do echo [+] %%V

:: ── 第2步：安装依赖 ───────────────────────────────────────────────────────────
echo.
echo [第 2/3 步] 检查依赖...
%PYTHON% -c "import cloakbrowser" >nul 2>&1
if errorlevel 1 (
    echo [!] 正在安装 cloakbrowser...
    %PYTHON% -m pip install cloakbrowser --quiet
    if errorlevel 1 (
        %PYTHON% -m pip install cloakbrowser --quiet --break-system-packages
    )
    echo [+] cloakbrowser 安装完成
) else (
    echo [+] cloakbrowser 已就绪
)
if exist requirements.txt (
    %PYTHON% -m pip install -r requirements.txt --quiet >nul 2>&1
)

:: ── 第3步：配置检查 ───────────────────────────────────────────────────────────
echo.
echo [第 3/3 步] 配置检查...

if "%MODE%"=="setup" goto :open_setup
if "%MODE%"=="login" goto :open_login
if not exist config.json (
    echo [!] 未找到 config.json，打开配置向导...
    goto :open_setup
)
echo [+] 已找到 config.json
goto :run

:open_setup
echo.
%PYTHON% setup.py
if not exist config.json (
    echo [!] 未保存配置，退出。
    pause
    exit /b 0
)
goto :run

:open_login
echo.
%PYTHON% setup.py --login
goto :run

:run
echo.
echo 开始签到...
echo.
if "%SITE_ARG%"=="" (
    %PYTHON% checkin.py
) else (
    %PYTHON% checkin.py %SITE_ARG%
)
echo.
pause
exit /b
