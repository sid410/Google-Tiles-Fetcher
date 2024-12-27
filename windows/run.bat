@echo off

set WSL_SETUP_URL=https://raw.githubusercontent.com/sid410/Google-Tiles-Fetcher/main/windows/wsl_setup.ps1
set WSL_MAP_SELECT_URL=https://raw.githubusercontent.com/sid410/Google-Tiles-Fetcher/main/windows/wsl_map_select.ps1

setlocal enabledelayedexpansion

curl --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo "Curl is available. Using curl for downloads."
    set USE_CURL=1
) else (
    echo "Curl is not available. Using PowerShell as fallback."
    set USE_CURL=0
)

if not exist "wsl_setup.ps1" (
    echo wsl_setup.ps1 not found. Downloading...
    if !USE_CURL! equ 1 (
        curl -o wsl_setup.ps1 %WSL_SETUP_URL%
    ) else (
        PowerShell -Command "Invoke-WebRequest -Uri '%WSL_SETUP_URL%' -OutFile 'wsl_setup.ps1'"
    )
    if %ERRORLEVEL% neq 0 (
        echo Failed to download wsl_setup.ps1. Exiting...
        exit /b 1
    )
)

if not exist "wsl_map_select.ps1" (
    echo wsl_map_select.ps1 not found. Downloading...
    if !USE_CURL! equ 1 (
        curl -o wsl_map_select.ps1 %WSL_MAP_SELECT_URL%
    ) else (
        PowerShell -Command "Invoke-WebRequest -Uri '%WSL_MAP_SELECT_URL%' -OutFile 'wsl_map_select.ps1'"
    )
    if %ERRORLEVEL% neq 0 (
        echo Failed to download wsl_map_select.ps1. Exiting...
        exit /b 1
    )
)

echo Running wsl_setup.ps1...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "wsl_setup.ps1"
if %ERRORLEVEL% neq 0 (
    echo wsl_setup.ps1 failed. Exiting...
    exit /b 1
)

echo Running wsl_map_select.ps1...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "wsl_map_select.ps1"
if %ERRORLEVEL% neq 0 (
    echo wsl_map_select.ps1 failed. Exiting...
    exit /b 1
)


echo Successfully fetched the Tiles.
pause
