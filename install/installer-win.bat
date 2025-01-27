@echo off

:: For temporarily updating the PATH variable
setlocal

:: Check for admin rights. Not sure if  there is a better way...
mkdir "%__APPDIR__%testadmincheck" >nul 2>&1
if not exist "%__APPDIR__%testadmincheck" (
    echo Error: This script must be run as an administrator.
    pause
    exit /b 1
)
rmdir "%__APPDIR__%testadmincheck" >nul 2>&1

where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: winget is not installed or not in PATH. Please install winget to proceed.
    pause
    exit /b 1
)

echo ============================================
echo Checking if Git is installed...
echo ============================================
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed. Installing Git...
    winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
) else (
    echo Git is already installed.
    goto VerifyGit
)

echo ============================================
echo Determining Git installation directory...
echo ============================================
set "GIT_DIR="
if exist "%ProgramFiles%\Git\cmd" set "GIT_DIR=%ProgramFiles%\Git"
if exist "%ProgramFiles(x86)%\Git\cmd" set "GIT_DIR=%ProgramFiles(x86)%\Git"

if "%GIT_DIR%"=="" (
    echo Error: Git installation directory not found.
    pause
    exit /b 1
)

echo Adding Git to PATH for this session...
set "PATH=%GIT_DIR%\bin;%GIT_DIR%\cmd;%PATH%"
echo PATH is now set as:
echo %PATH%

if "%PATH:~8192,1%" neq "" (
    echo Warning: PATH length exceeds Windows limits, which might cause issues.
    pause
)

:VerifyGit
echo ============================================
echo Verifying Git installation...
echo ============================================
git --version
if %errorlevel% neq 0 (
    echo Error: Git installation verification failed. Please restart CMD or check your PATH.
    pause
    exit /b 1
)

echo ============================================
echo Cloning Google-Tiles-Fetcher repository...
echo ============================================

set "TARGET_DIR=C:\Program Files\Google-Tiles-Fetcher"

if exist "%TARGET_DIR%" (
    echo Directory "%TARGET_DIR%" already exists. Delete this directory first to reinstall.
) else (
    git clone https://github.com/sid410/Google-Tiles-Fetcher.git "%TARGET_DIR%"
    if %errorlevel% neq 0 (
        echo Error: Failed to clone the repository. Please check the GitHub URL or your network connection.
        pause
        exit /b 1
    )
)

echo ============================================
echo Checking for the blender_addon...
echo ============================================

set "ADDON_DIR=%TARGET_DIR%\blender_addon"
if not exist "%ADDON_DIR%" (
    echo blender_addon folder does not exist. Creating it...
    mkdir "%ADDON_DIR%"
    if %errorlevel% neq 0 (
        echo Error: Failed to create blender_addon folder. Please check permissions.
        pause
        exit /b 1
    )
) else (
    echo blender_addon folder already exists.
)

set "ADDON_FILE=%ADDON_DIR%\blosm_2.7.10.zip"
if not exist "%ADDON_FILE%" (
    echo blosm_2.7.10.zip not found. Attempting to download with curl...
    
    curl -L -o "%ADDON_FILE%" "https://drive.google.com/uc?export=download&id=1Ga8J8azsYzR0Ubb3xSb-BSaq1B2fPDfX" >nul 2>&1
    if %errorlevel% neq 0 (
        echo curl download failed. Falling back to PowerShell...
        
        powershell -Command "try { Invoke-WebRequest -Uri 'https://drive.google.com/uc?export=download&id=1Ga8J8azsYzR0Ubb3xSb-BSaq1B2fPDfX' -OutFile '%ADDON_FILE%' } catch { exit 1 }"
        if %errorlevel% neq 0 (
            echo Error: Failed to download blosm_2.7.10.zip using both curl and PowerShell. Please check your internet connection.
            pause
            exit /b 1
        )
    ) else (
        echo Download successful with curl.
    )
) else (
    echo blosm_2.7.10.zip already exists.
)

echo ============================================
echo Running install-blenderWin.bat...

set "INSTALL_BLENDER_SCRIPT=%TARGET_DIR%\install\install-blenderWin.bat"
if exist "%INSTALL_BLENDER_SCRIPT%" (
    call "%INSTALL_BLENDER_SCRIPT%"
    if %errorlevel% neq 0 (
        echo Error: install-blenderWin.bat encountered an error.
        pause
        exit /b 1
    )
) else (
    echo Error: install-blenderWin.bat not found in the expected location: %INSTALL_BLENDER_SCRIPT%.
    pause
    exit /b 1
)

echo ============================================
echo Creating a shortcut for fetch.bat on the Desktop...

set "FETCH_BAT=%TARGET_DIR%\fetch.bat"
set "SHORTCUT_PATH="
set "DESKTOP_DIR="

:: Temporary file to store PowerShell output
set "TEMP_DESKTOP_FILE=%TEMP%\desktop_path.txt"

:: Determine the Desktop directory and write it to a temp file
powershell -NoProfile -Command "try { $Desktop = [Environment]::GetFolderPath('Desktop'); if (!(Test-Path -Path $Desktop)) { $Desktop = Join-Path $env:USERPROFILE 'OneDrive\Desktop'; if (!(Test-Path -Path $Desktop)) { exit 1 } }; $Desktop | Out-File -FilePath '%TEMP_DESKTOP_FILE%' -Encoding ASCII -NoNewline } catch { exit 1 }"

:: Read the desktop path from the temp file
if exist "%TEMP_DESKTOP_FILE%" (
    set /p "DESKTOP_DIR=" < "%TEMP_DESKTOP_FILE%"
    del "%TEMP_DESKTOP_FILE%"
) else (
    echo Error: Unable to determine Desktop directory.
    pause
    exit /b 1
)

set "SHORTCUT_PATH=%DESKTOP_DIR%\fetch.lnk"
echo DEBUG: DESKTOP_DIR=%DESKTOP_DIR%
echo DEBUG: SHORTCUT_PATH=%SHORTCUT_PATH%

if not exist "%FETCH_BAT%" (
    echo Error: fetch.bat not found at the repository root: %FETCH_BAT%.
    pause
    exit /b 1
)

:: Create the shortcut using PowerShell command
powershell -NoProfile -Command "try { $WScriptShell = New-Object -ComObject WScript.Shell; $Shortcut = $WScriptShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%FETCH_BAT%'; $Shortcut.WorkingDirectory = '%TARGET_DIR%'; $Shortcut.IconLocation = '%SystemRoot%\System32\shell32.dll,1'; $Shortcut.Save() } catch { exit 1 }"

if %errorlevel% neq 0 (
    echo Error: Failed to create the shortcut for fetch.bat.
    pause
    exit /b 1
) else (
    echo Shortcut for fetch.bat successfully created on the Desktop.
)

echo ============================================
echo Successfully installed everything. You can now close this and run `fetch` as admin.

pause
exit /b 0
