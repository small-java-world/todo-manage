# Port block test script
# NOTE: This requires administrator privileges

Write-Host "Setting up port proxy to block port 8000..."

$ListenAddress = "0.0.0.0"
$ListenPort    = 8000
$ConnectAddr   = "127.0.0.1"
$ConnectPort   = 65535

try {
    netsh interface portproxy add v4tov4 `
        listenaddress=$ListenAddress listenport=$ListenPort `
        connectaddress=$ConnectAddr connectport=$ConnectPort

    Write-Host "`nPort proxy added successfully. Port 8000 is now blocked."

    # Show current portproxy settings
    Write-Host "`nCurrent portproxy settings:"
    netsh interface portproxy show all

    # Try to start docker compose (this should fail)
    Write-Host "`nAttempting to start docker compose (expected to fail)..."
    Set-Location D:\todo-manage\todo-api
    docker compose up -d

    Start-Sleep -Seconds 5

    # Capture logs
    Write-Host "`nCapturing error logs..."
    docker compose logs todo-api --tail 100 | Out-File -FilePath ..\logs\port-conflict.log -Encoding utf8

    Write-Host "Logs saved to logs\port-conflict.log"

    # Stop any running containers
    docker compose down

} catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
}
