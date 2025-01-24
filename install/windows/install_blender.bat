@echo off
setlocal enabledelayedexpansion
goto :Main

:: --- Subroutine for downloading files
:DownloadFile
:: %1 - URL
:: %2 - Output file
if "%~1"=="" (
    echo Error: URL not specified for download.
    exit /b 1
)
if "%~2"=="" (
    echo Error: Output file path not specified for download.
    exit /b 1
)

echo Attempting to download: %~1
curl -L -o "%~2" "%~1"
if %errorlevel% neq 0 (
    echo Curl failed to download. Falling back to PowerShell...
    powershell -Command "try { Invoke-WebRequest -Uri '%~1' -OutFile '%~2' -ErrorAction Stop } catch { exit 1 }"
)
exit /b
:: ---

:: --- Subroutines below especially for Visual C++ Redistributable
:WaitForFile
:: Ensure file is fully downloaded before proceeding
:: %1 - File path to check
set "FILE_READY=0"
for /l %%i in (1,1,10) do (
    if exist "%~1" (
        set "FILE_READY=1"
        goto :EOF
    )
    echo Waiting for file "%~1" to be ready... (Attempt %%i of 10)
    timeout /t 1 >nul
)
if "!FILE_READY!"=="0" (
    echo [ERROR] File "%~1" did not become ready in time. Exiting.
    exit /b 1
)
goto :EOF

:: --- Another subroutine for Visual C++ Redistributable
:CheckDLLs
:: Check if required runtime DLLs are present
set "DLLS_TO_CHECK=msvcp140.dll vcruntime140.dll msvcp140_1.dll"
set "DLL_FOUND=1"

for %%D in (%DLLS_TO_CHECK%) do (
    if not exist "%WINDIR%\\System32\\%%D" (
        echo Missing required DLL: %%D
        set "DLL_FOUND=0"
    )
)

:: Return the result
set "CHECK_DLL_RESULT=!DLL_FOUND!"
exit /b
:: ---


:: ------------ Start the main logic here
:Main
:: Variables
set "VC_REDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "VC_REDIST_FILE=vc_redist.x64.exe"
set "BLENDER_DOWNLOAD_URL=https://mirror.freedif.org/blender/release/Blender4.2/blender-4.2.6-windows-x64.msi"
set "BLENDER_FILE=Blender.msi"
set "BLENDER_INSTALL_DIR=C:\Program Files\Blender Foundation\Blender 4.2"

echo ============================================
echo Checking for Visual C++ Redistributable...
echo ============================================

call :CheckDLLs

if "!CHECK_DLL_RESULT!"=="0" (
    goto :DownloadAndInstall
) else (
    goto :AlreadyInstalled
)

:DownloadAndInstall
echo ============================================
echo Missing required DLLs. Proceeding to download and install Visual C++ Redistributable...
echo ============================================

echo Downloading from URL: "%VC_REDIST_URL%" to file: "%VC_REDIST_FILE%"
call :DownloadFile "%VC_REDIST_URL%" "%VC_REDIST_FILE%"

:: Ensure file is fully downloaded
call :WaitForFile "%VC_REDIST_FILE%"

if not exist "%VC_REDIST_FILE%" (
    echo [ERROR] Download failed or file "%VC_REDIST_FILE%" does not exist. Exiting.
    exit /b 1
)

:: Debug: Verify the downloaded file
echo [DEBUG] Verifying downloaded file: "%VC_REDIST_FILE%"

:: Install the downloaded file
echo Installing Visual C++ Redistributable from: "%VC_REDIST_FILE%"
"%VC_REDIST_FILE%" /install /quiet /norestart > install_log.txt 2>&1
set "INSTALL_RESULT=%errorlevel%"

:: Debug: Log the installation result
echo [DEBUG] INSTALL_RESULT: "!INSTALL_RESULT!"
if "!INSTALL_RESULT!" neq "0" (
    echo [ERROR] Installation failed with exit code "!INSTALL_RESULT!". Check install_log.txt for details.
    pause
    exit /b 1
)

:: Recheck for missing DLLs
echo Rechecking Visual C++ Redistributable installation...
call :CheckDLLs

if "!CHECK_DLL_RESULT!"=="0" (
    echo [ERROR] DLLs are still missing after installation. Exiting.
    pause
    exit /b 1
) else (
    echo Visual C++ Redistributable installed successfully.
)

goto :EndVcRedis

:AlreadyInstalled
echo Visual C++ Redistributable is already installed. Proceeding...

:EndVcRedis
echo ============================================
echo Visual C++ Redistributable setup complete!



echo ============================================
echo Checking if Blender is installed...

if exist "%BLENDER_INSTALL_DIR%\blender.exe" (
    echo Blender is already installed at "%BLENDER_INSTALL_DIR%".
    echo Skipping installation steps.
    goto UpdatePath
)

echo ============================================
echo Downloading Blender installer...

echo Downloading from URL: "%BLENDER_DOWNLOAD_URL%" to file: "%BLENDER_FILE%"
call :DownloadFile "%BLENDER_DOWNLOAD_URL%" "%BLENDER_FILE%"
if not exist "%BLENDER_FILE%" (
    echo Failed to download the installer. Exiting.
    exit /b 1
)

echo ============================================
echo Installing Blender...

msiexec /i "%BLENDER_FILE%" /passive
if %errorlevel% neq 0 (
    echo Installation failed. Exiting.
    exit /b 1
)

:UpdatePath
echo ============================================
echo Adding Blender to PATH permanently...
echo ============================================

for /f "tokens=*" %%A in ('powershell -command "[System.Environment]::GetEnvironmentVariable('Path', 'Machine')"') do set "CURRENT_PATH=%%A"
echo %CURRENT_PATH% | find "%BLENDER_INSTALL_DIR%" >nul
if %errorlevel% neq 0 (
    setx Path "%CURRENT_PATH%;%BLENDER_INSTALL_DIR%" /M
    echo Blender path added permanently to the system PATH.
) else (
    echo Blender path is already in the system PATH.
)

for /f "tokens=*" %%A in ('powershell -command "[System.Environment]::GetEnvironmentVariable('Path', 'Machine')"') do set "PATH=%%A"
echo PATH reloaded for this session.

echo ============================================
echo Verifying Blender installation...
echo ============================================

blender --version
if %errorlevel% neq 0 (
    echo Blender installation verification failed. Exiting.
    exit /b 1
)

echo ============================================
echo Finding Blender's Python path...
echo ============================================

set "BLENDER_PYTHON_PATH="
for /f "usebackq tokens=*" %%A in (`blender --background --python-expr "import sys; print(sys.executable)" 2^>nul`) do (
    echo %%A | findstr /c:"python.exe" >nul
    if not errorlevel 1 (
        set "BLENDER_PYTHON_PATH=%%A"
        goto PathFound
    )
)

:PathFound
if defined BLENDER_PYTHON_PATH (
    echo Blender's Python path is: %BLENDER_PYTHON_PATH%
) else (
    echo Failed to find Blender's Python path.
    exit /b 1
)

echo ============================================
echo Ensuring pip is installed and installing required Python packages...
echo ============================================

"%BLENDER_PYTHON_PATH%" -m ensurepip --upgrade
if %errorlevel% neq 0 (
    echo Failed to ensure pip is installed. Exiting.
    exit /b 1
)

"%BLENDER_PYTHON_PATH%" -m pip install --upgrade pip
if %errorlevel% neq 0 (
    echo Failed to upgrade pip. Exiting.
    exit /b 1
)

"%BLENDER_PYTHON_PATH%" -m pip install pyyaml
if %errorlevel% neq 0 (
    echo Failed to install pyyaml. Exiting.
    exit /b 1
)

"%BLENDER_PYTHON_PATH%" -m pip install flask
if %errorlevel% neq 0 (
    echo Failed to install flask. Exiting.
    exit /b 1
)

"%BLENDER_PYTHON_PATH%" -c "import yaml, flask; print('pyyaml version:', yaml.__version__); print('flask version:', flask.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo Failed to verify installed Python packages. Exiting.
    exit /b 1
) else (
    echo Python packages verified successfully.
)

echo ============================================
echo Cleaning up downloaded files...
echo ============================================

del "%VC_REDIST_FILE%"
del "%BLENDER_FILE%"

echo ============================================
echo Blender related setup complete!
echo ============================================

exit /b
