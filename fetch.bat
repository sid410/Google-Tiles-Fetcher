@echo off
setlocal

:: Check for admin rights. Not sure if  there is a better way...
mkdir "%__APPDIR__%testadmincheck" >nul 2>&1
if not exist "%__APPDIR__%testadmincheck" (
    echo Error: This script must be run as an administrator.
    pause
    exit /b 1
)
rmdir "%__APPDIR__%testadmincheck" >nul 2>&1

:: cd to where it is opened, just in case it jumps to system32
cd /d "%~dp0"

start "Blender Process" cmd /c "blender --background --python main.py -- map_select_ui"

:: Loop to check if the server is up
echo Waiting for http://localhost:5000 to start...
:check_server
timeout /t 2 >nul
powershell -Command "(Invoke-WebRequest -Uri http://localhost:5000 -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode -eq 200" >nul 2>&1
if %errorlevel% neq 0 (
    goto check_server
)

:: Once the server is up, open the browser
start http://localhost:5000/

echo Server started successfully.
endlocal
