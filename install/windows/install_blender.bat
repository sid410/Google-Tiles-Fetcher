@echo off

:: Define variables
set "VC_REDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "VC_REDIST_FILE=vc_redist.x64.exe"
set "DOWNLOAD_URL=https://mirror.freedif.org/blender/release/Blender4.2/blender-4.2.6-windows-x64.msi"
set "OUTPUT_FILE=Blender.msi"
set "INSTALL_DIR=C:\Program Files\Blender Foundation\Blender 4.2"

:: Step 0: Ensure Visual C++ Redistributable is installed
echo Checking for Visual C++ Redistributable...
set "VC_REDIST_CHECK="
for /f "tokens=*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Installed 2^>nul') do set "VC_REDIST_CHECK=%%A"

if not defined VC_REDIST_CHECK (
    echo Visual C++ Redistributable not found. Downloading and installing...
    curl -L -o "%VC_REDIST_FILE%" "%VC_REDIST_URL%"
    if exist "%VC_REDIST_FILE%" (
        echo Successfully downloaded Visual C++ Redistributable. Proceeding with installation...
        "%VC_REDIST_FILE%" /install /quiet /norestart
        set "INSTALL_RESULT=%errorlevel%"
        
        :: Check if the installation was successful or if it is already installed
        echo Checking Visual C++ Redistributable installation status...
        for /f "tokens=*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Installed 2^>nul') do set "VC_REDIST_CHECK=%%A"
        if defined VC_REDIST_CHECK (
            echo Visual C++ Redistributable is installed successfully.
        ) else (
            echo Failed to install Visual C++ Redistributable. Exiting.
            exit /b 1
        )
    ) else (
        echo Failed to download Visual C++ Redistributable. Exiting.
        exit /b 1
    )
) else (
    echo Visual C++ Redistributable is already installed.
)


:: Step 1: Check if Blender is already installed
if exist "%INSTALL_DIR%\blender.exe" (
    echo Blender is already installed at "%INSTALL_DIR%".
    echo Skipping installation steps.
    goto UpdatePath
)

:: Step 2: Download Blender MSI installer
echo Downloading Blender installer...
curl -L -o "%OUTPUT_FILE%" "%DOWNLOAD_URL%"
if %errorlevel% neq 0 (
    echo Failed to download the installer. Exiting.
    exit /b 1
)

:: Step 3: Install Blender (passive mode)
echo Installing Blender (passive mode)...
msiexec /i "%OUTPUT_FILE%" /passive
if %errorlevel% neq 0 (
    echo Installation failed. Exiting.
    exit /b 1
)

:UpdatePath
:: Step 4: Permanently update PATH
echo Adding Blender to PATH permanently...

for /f "tokens=*" %%A in ('powershell -command "[System.Environment]::GetEnvironmentVariable('Path', 'Machine')"') do set "CURRENT_PATH=%%A"
echo %CURRENT_PATH% | find "%INSTALL_DIR%" >nul
if %errorlevel% neq 0 (
    setx Path "%CURRENT_PATH%;%INSTALL_DIR%" /M
    echo Blender path added permanently to the system PATH.
) else (
    echo Blender path is already in the system PATH.
)

:: Reload the PATH for the current session
for /f "tokens=*" %%A in ('powershell -command "[System.Environment]::GetEnvironmentVariable('Path', 'Machine')"') do set "PATH=%%A"
echo PATH reloaded for this session.

:: Verify Blender installation
echo Verifying Blender installation...
blender --version
if %errorlevel% neq 0 (
    echo Blender installation verification failed. Exiting.
    exit /b 1
)

:: Step 5: Find Blender's Python path
echo Finding Blender's Python path...
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

:: Step 6: Ensure pip and install Python packages
echo Ensuring pip is installed and installing required Python packages...
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

:: Step 7: Clean up downloaded files
del "%VC_REDIST_FILE%"
del "%OUTPUT_FILE%"

:: Step 8: Finish
echo Blender related installation complete!
pause
