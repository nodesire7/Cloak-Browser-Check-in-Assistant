@echo off
:: Cloak Browser Check-in Assistant
:: https://cloakbrowser.dev
::
:: Usage:
::   run.bat           Auto-setup on first run, then check in
::   run.bat --setup   Open setup wizard (add / edit / remove sites)
::   run.bat --login   Clear cookies and force re-login
::   run.bat <site>    Check in for one site only (e.g. ourbits)

cd /d "%~dp0"

:: ---- parse args -------------------------------------------------------------
set "MODE=checkin"
set "SITE_ARG="
if "%~1"=="--setup" set "MODE=setup"
if "%~1"=="--login" set "MODE=login"
if "%~1"=="--help"  goto :help
if "%~1"=="/?"      goto :help
if not "%~1"=="" (
    if not "%~1"=="--setup" if not "%~1"=="--login" set "SITE_ARG=%~1"
)
goto :detect_python

:help
echo Usage: run.bat [--setup^|--login^|^<site^>]
echo.
echo   (no args)   Auto-setup on first run, then check in all sites
echo   --setup     Open setup wizard (add / edit / remove sites)
echo   --login     Clear cookies and force re-login
echo   ^<site^>     Check in for one site only (e.g. ourbits)
exit /b 0

:: ---- step 1: detect Python --------------------------------------------------
:detect_python
set "PYTHON="
python --version >nul 2>&1
if not errorlevel 1 (set "PYTHON=python" & goto :python_ok)
python3 --version >nul 2>&1
if not errorlevel 1 (set "PYTHON=python3" & goto :python_ok)

echo [-] Python 3.8+ not found.
echo.
echo     Download: https://www.python.org/downloads/
echo     Check "Add Python to PATH" during install.
echo.
pause
exit /b 1

:python_ok
for /f "tokens=*" %%V in ('%PYTHON% --version 2^>^&1') do echo [+] %%V found.

:: ---- step 2: install dependencies ------------------------------------------
echo.
%PYTHON% -c "import cloakbrowser" >nul 2>&1
if errorlevel 1 (
    echo [*] Installing cloakbrowser...
    %PYTHON% -m pip install cloakbrowser --quiet
    if errorlevel 1 %PYTHON% -m pip install cloakbrowser --quiet --break-system-packages
    echo [+] cloakbrowser installed.
) else (
    echo [+] cloakbrowser ready.
)
if exist requirements.txt %PYTHON% -m pip install -r requirements.txt --quiet >nul 2>&1

:: ---- step 3: config / dispatch ----------------------------------------------
echo.
if "%MODE%"=="setup" goto :open_setup
if "%MODE%"=="login" goto :open_login
if not exist config.json (
    echo [*] config.json not found. Opening setup wizard...
    goto :open_setup
)
echo [+] config.json found.
goto :run

:open_setup
echo.
%PYTHON% setup.py
if not exist config.json (
    echo [!] No config saved. Exiting.
    pause
    exit /b 0
)
if "%MODE%"=="setup" exit /b 0
goto :run

:open_login
%PYTHON% setup.py --login
goto :run

:: ---- run check-in -----------------------------------------------------------
:run
echo.
if "%SITE_ARG%"=="" (
    %PYTHON% checkin.py
) else (
    %PYTHON% checkin.py "%SITE_ARG%"
)
echo.
pause
exit /b
