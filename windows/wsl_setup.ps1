$wslStatus = wsl --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL is not installed. Installing WSL..."

    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

    Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile wsl_update_x64.msi
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i wsl_update_x64.msi /quiet" -Wait
    Write-Host "WSL features installed. Please restart your computer."
    exit
}

Write-Host "WSL is installed. Checking for the latest Ubuntu distribution..."


$distros = wsl --list | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
Write-Host "Distros Installed: $distros"

if ($distros -notcontains "Ubuntu") {
    Write-Host "Ubuntu is not installed. Installing the latest Ubuntu version..."
    wsl --install -d Ubuntu
    Write-Host "Ubuntu installation is complete. Please restart your computer."
    exit
} else {
    Write-Host "Ubuntu is already installed. Proceeding..."
}


Write-Host "Ubuntu is installed. Proceeding with project setup..."


$wslUsername = wsl -d Ubuntu -- whoami
$projectPath = "/home/$wslUsername/Google-Tiles-Fetcher"


Write-Host "Checking if the repository exists at $projectPath..."
$repoExists = wsl -d Ubuntu -- bash -c "[ -d $projectPath ] && echo exists || echo notexists"

if ($repoExists -match "notexists") {
    Write-Host "Repository does not exist. Cloning into $projectPath..."
    wsl -d Ubuntu -- bash -c "cd /home/$wslUsername && git clone https://github.com/sid410/Google-Tiles-Fetcher.git"
} else {
    Write-Host "Repository already exists. Skipping clone step."
}


Write-Host "Running the setup script..."
wsl -d Ubuntu -- bash -c "cd $projectPath && chmod +x install.sh && ./install.sh"
