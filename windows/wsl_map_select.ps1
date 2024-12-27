$wslUsername = wsl -d Ubuntu -- whoami
$projectPath = "/home/$wslUsername/Google-Tiles-Fetcher"

Start-Job -ScriptBlock {
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:5000/"
}

Write-Host "Running server for interactive map..."
wsl -d Ubuntu -- bash -c "cd $projectPath && blender --background --python main.py -- map_select_ui"
