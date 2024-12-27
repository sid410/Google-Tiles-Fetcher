Clear-Host

$wslUsername = wsl -d Ubuntu -- whoami | ForEach-Object { $_.Trim() }
$projectPath = "/home/$wslUsername/Google-Tiles-Fetcher"

Start-Job -ScriptBlock {
    while (-not (Test-NetConnection -ComputerName "localhost" -Port 5000).TcpTestSucceeded) {
        Start-Sleep -Seconds 1
    }
    Start-Process "http://localhost:5000/"
}

Write-Host "Running server for interactive map..."
wsl -d Ubuntu -- bash -c "cd $projectPath && blender --background --python main.py -- map_select_ui"
